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
import urllib.request
import re
import ssl
import awsutils


def get_ubuntu_ami(region, release, arch='amd64', instance_type='hvm:ebs-ssd'):
    # https://aws.amazon.com/amazon-linux-ami/instance-type-matrix/
    # https://cloud-images.ubuntu.com/locator/ec2/  -> Js console -> Network
    ssl._create_default_https_context = ssl._create_unverified_context
    ami_list = yaml.safe_load(urllib.request.urlopen("https://cloud-images.ubuntu.com/locator/ec2/releasesTable").read())['aaData']
    # Items look like:
    #['us-east-1',
    # 'artful',
    # '17.10',
    # 'amd64',
    # 'hvm:instance-store',
    # '20180621',
    # '<a href="https://console.aws.amazon.com/ec2/home?region=us-east-1#launchAmi=ami-71e2b40e">ami-71e2b40e</a>',
    # 'hvm']
    res = [x for x in ami_list if x[0] == region and x[2].startswith(release) and x[3] == arch and x[4] == instance_type]
    ami_link = res[0][6]
    ami_id = re.sub('<[^<]+?>', '', ami_link)
    return ami_id



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

def create_instances(ec2, tag, instance_type, keyName, ami, security_groups, create_instance_kwargs, instanceCount=1):
    logging.info("Launching {} instances".format(instanceCount))
    kwargs = { 'ImageId': ami
        , 'MinCount': instanceCount
        , 'MaxCount': instanceCount
        , 'KeyName': keyName
        , 'InstanceType': instance_type
        , 'UserData': assemble_userdata().as_string()
        , 'SecurityGroupIds': security_groups
    }
    kwargs.update(create_instance_kwargs)
    instances = ec2.create_instances(**kwargs)
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


def parse_args():
    with open('launch_template.yml', 'r') as f:
        launch_template = yaml.load(f)
    parser = argparse.ArgumentParser(description="launcher")
    parser.add_argument('-n', '--instance-name', default=launch_template.get('instance-name', "{}-{}".format('worker', getpass.getuser())))
    parser.add_argument('-i', '--instance-type', default=launch_template.get('instance-type'))
    parser.add_argument('--ubuntu', default=launch_template.get('ubuntu'))
    parser.add_argument('-u', '--username',
                        default=launch_template.get('username', getpass.getuser()))
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
        #"-v",
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

    boto3_session = boto3.session.Session()
    current_region = boto3_session.region_name
    logging.info("AWS Region is %s", current_region)

    instance_name = input("instance_name [{}]: ".format(args.instance_name))
    if not instance_name:
        instance_name = args.instance_name

    instance_type = input("instance_type (https://www.ec2instances.info) [{}]: ".format(args.instance_type))
    if not instance_type:
        instance_type = args.instance_type

    ssh_key_file = input("(public) ssh_key_file [{}]: ".format(args.ssh_key_file))
    if not ssh_key_file:
        ssh_key_file = args.ssh_key_file
    assert os.path.isfile(ssh_key_file)

    ubuntu = input("ubuntu release (or specific 'ami') [{}]: ".format(args.ubuntu))
    if not ubuntu:
        ubuntu = args.ubuntu

    if ubuntu.startswith('ami') or ubuntu.startswith('aki'):
        args.ami = ubuntu
        ubuntu = None

    if not ubuntu:
        ami = input("ami [{}]: ".format(args.ami))
        if not ami:
            ami = args.ami
    else:
        ami = get_ubuntu_ami(current_region, ubuntu)
        logging.info("Automatic Ubuntu ami selection based on region %s and release %s -> AMI id: %s",
                     current_region, ubuntu, ami)

    username = input("user name [{}]: ".format(args.username))
    if not username:
        username = args.username

    ec2_resource = boto3.resource('ec2')
    ec2_client = boto3.client('ec2')

    try:
        logging.info("Creating security groups")
        security_groups = create_security_groups(ec2_client, ec2_resource)
    except botocore.exceptions.ClientError as e:
        logging.info("Continuing: Security group might already exist or be used by a running instance")
        res = ec2_client.describe_security_groups(GroupNames=['ssh_anywhere'])
        security_groups = [res['SecurityGroups'][0]['GroupId']]



    try:
        ec2_client.import_key_pair(KeyName=args.ssh_key_name, PublicKeyMaterial=read_ssh_key(ssh_key_file))
    except botocore.exceptions.ClientError as e:
        logging.info("Continuing: Key pair '%s' might already exist", args.ssh_key_name)

    logging.info("creating instances")
    with open('launch_template.yml', 'r') as f:
        launch_template = yaml.load(f)
    instances = create_instances(
        ec2_resource,
        instance_name,
        instance_type,
        args.ssh_key_name,
        ami,
        security_groups,
        launch_template.get('CreateInstanceArgs', {}))

    awsutils.wait_for_instances(instances)
    hosts = [i.public_dns_name for i in instances]
    for host in hosts:
        logging.info("Waiting for host {}".format(host))
        awsutils.wait_port_open(host, 22, 300)
        provision(host, username)

    logging.info("All done, the following hosts are now available: %s", hosts)
    return 0

if __name__ == '__main__':
    sys.exit(main())

