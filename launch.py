#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import sys
import subprocess
import glob
import logging
import argparse
import getpass
import boto3
from os.path import expanduser
from subprocess import call, check_call
import botocore
import yaml


def wait_port_open(server, port, timeout=None):
    """ Wait for network service to appear
        @param server: host to connect to (str)
        @param port: port (int)
        @param timeout: in seconds, if None or 0 wait forever
        @return: True of False, if timeout is None may return only True or
                 throw unhandled network exception
    """
    import socket
    import errno
    import time
    sleep_s = 0
    if timeout:
        from time import time as now
        # time module is needed to calc timeout shared between two exceptions
        end = now() + timeout

    while True:
        logging.debug("Sleeping for %s second(s)", sleep_s)
        time.sleep(sleep_s)
        s = socket.socket()
        try:
            if timeout:
                next_timeout = end - now()
                if next_timeout < 0:
                    return False
                else:
                    s.settimeout(next_timeout)

            logging.info("connect %s %d", server, port)
            s.connect((server, port))

        except ConnectionError as err:
            logging.debug("ConnectionError %s", err)
            if sleep_s == 0:
                sleep_s = 1

        except socket.gaierror as err:
            logging.debug("gaierror %s",err)
            return False

        except socket.timeout as err:
            # this exception occurs only if timeout is set
            if timeout:
                return False

        except TimeoutError as err:
            # catch timeout exception from underlying network library
            # this one is different from socket.timeout
            raise

        else:
            s.close()
            logging.info("wait_port_open: port %s:%s is open", server, port)
            return True



def assemble_userdata():
    from email.mime.multipart import MIMEMultipart
    from email.mime.text import MIMEText
    combined_message = MIMEMultipart()
    userdata_files = [
        ('userdata.py', 'text/x-shellscript'),
        ('cloud-config', 'text/cloud-config')
    ]
    for fname, mimetype in userdata_files:
        with open(fname, "r") as f:
            content = f.read()
        sub_message = MIMEText(content, mimetype, sys.getdefaultencoding())
        sub_message.add_header('Content-Disposition', 'attachment; filename="{}"'.format(fname))
        combined_message.attach(sub_message)
    return combined_message

def create_instances(ec2, tag, instance_type, keyName, ami, security_groups, blockDeviceMappings, instanceCount=1):
    logging.info("Launching {} instances".format(instanceCount))
    instances = ec2.create_instances(
        ImageId = ami
        , BlockDeviceMappings = blockDeviceMappings
        , MinCount = instanceCount
        , MaxCount = instanceCount
        , KeyName = keyName
        , InstanceType = instance_type
        #, Placement = {'AvailabilityZone': 'eu-central-1a'}
        , UserData = assemble_userdata().as_string()
        , SecurityGroupIds = security_groups
    )
    ec2.create_tags(
        Resources = [instance.id for instance in instances]
        , Tags = [
          {'Key': 'Name', 'Value': tag}
        ]
    )

    return instances

def create_security_groups(ec2_client, ec2_resource):
    sec_group_name = 'ssh_anywhere'
    try:
        ec2_client.delete_security_group(GroupName=sec_group_name)
    except:
        pass
    sg = ec2_resource.create_security_group(
        GroupName=sec_group_name,
        Description='SSH from anywhere')
    resp = ec2_client.authorize_security_group_ingress(
        GroupId=sg.id,
        IpPermissions=[
            {'IpProtocol': 'tcp',
             'FromPort': 22,
             'ToPort': 22,
             'IpRanges': [{'CidrIp': '0.0.0.0/0'}]}
        ])
    return [sec_group_name]

def wait_for_instances(instances):
    """
    Wait until the given boto3 instance objects are running
    """
    logging.info("Waiting for instances: {}".format([i.id for i in instances]))
    for i in instances:
        logging.info("Waiting for instance {}".format(i.id))
        i.wait_until_running()
        logging.info("Instance {} running".format(i.id))

    client = boto3.client('ec2')
    waiter = client.get_waiter('instance_status_ok')
    logging.info("Waiting for instances to initialize (status ok): {}".format([i.id for i in instances]))
    waiter.wait(InstanceIds=[i.id for i in instances])
    logging.info("EC2 instances are ready to roll")
    for i in instances:
        i.reload()

def parse_args():
    with open('launch_template.yml', 'r') as f:
        launch_template = yaml.load(f)
    parser = argparse.ArgumentParser(description="launcher")
    parser.add_argument('-n', '--instance-name', default=launch_template.get('instance-name', "{}-{}".format('worker', getpass.getuser())))
    parser.add_argument('-i', '--instance-type', default=launch_template['instance-type'])
    parser.add_argument('-u', '--username', default=launch_template['username'])
    ssh_key = launch_template.get('ssh-key', os.path.join(expanduser("~"),".ssh","id_rsa.pub"))
    parser.add_argument('--ssh-key-file', default=ssh_key)
    parser.add_argument('--ssh-key-name', default="ssh_{}_key".format(getpass.getuser()))
    parser.add_argument('-a', '--ami', default=launch_template['ami'])
    parser.add_argument('rest', nargs='*')
    args = parser.parse_args()
    return args

def read_ssh_key(file):
    with open(file, 'r') as f:
        return f.read()

def config_logging():
    def script_name() -> str:
        return os.path.split(sys.argv[0])[1]
    logging.getLogger().setLevel(logging.DEBUG)
    logging.basicConfig(format='{}: %(asctime)-15s %(message)s'.format(script_name()))
    logging.getLogger('botocore').setLevel(logging.INFO)
    logging.getLogger('boto3').setLevel(logging.INFO)
    logging.getLogger('urllib3').setLevel(logging.INFO)
    logging.getLogger('s3transfer').setLevel(logging.INFO)

def provision(host, username):
    assert host
    assert username
    ansible_cmd= [
        "ansible-playbook",
        "-v",
        "-u", "ubuntu",
        "-i", "{},".format(host),
        "playbook.yml",
        "--extra-vars", "user_name={}".format(username)]

    logging.info("Executing: '{}'".format(' '.join(ansible_cmd)))
    os.environ['ANSIBLE_HOST_KEY_CHECKING']='False'
    check_call(ansible_cmd)


def main():
    # Launch a new instance each time by removing the state, otherwise tf will destroy the existing
    # one first
    def script_name() -> str:
        return os.path.split(sys.argv[0])[1]

    config_logging()

    args = parse_args()

    for f in glob.glob("*.tfstate"):
        os.remove(f)

    instance_name = input("instance_name [{}]: ".format(args.instance_name))
    if not instance_name:
        instance_name = args.instance_name

    instance_type = input("instance_type [{}]: ".format(args.instance_type))
    if not instance_type:
        instance_type = args.instance_type

    ssh_key_file = input("(public) ssh_key_file [{}]: ".format(args.ssh_key_file))
    if not ssh_key_file:
        ssh_key_file = args.ssh_key_file
    assert os.path.isfile(ssh_key_file)

    ami = input("ami [{}]: ".format(args.ami))
    if not ami:
        ami = args.ami

    username = input("user name [{}]: ".format(args.username))
    if not username:
        username = args.username

    ec2_resource = boto3.resource('ec2')
    ec2_client = boto3.client('ec2')

    try:
        logging.info("Creating security groups")
        security_groups = create_security_groups(ec2_client, ec2_resource)
        ec2_client.import_key_pair(KeyName=args.ssh_key_name, PublicKeyMaterial=read_ssh_key(ssh_key_file))
    except botocore.exceptions.ClientError as e:
        logging.exception("Security group might already exist or be used by a running instance")
        security_groups = ['ssh_anywhere']

    logging.info("creating instances")
    with open('launch_template.yml', 'r') as f:
        launch_template = yaml.load(f)
    instances = create_instances(ec2_resource, instance_name, instance_type, args.ssh_key_name, ami,
    security_groups, launch_template['BlockDeviceMappings'])
    wait_for_instances(instances)
    hosts = [i.public_dns_name for i in instances]
    for host in hosts:
        logging.info("Waiting for host {}".format(host))
        wait_port_open(host, 22, 300)
        provision(host, username)

    logging.info("All done, the following hosts are now available: %s", hosts)
    return 0

if __name__ == '__main__':
    sys.exit(main())

