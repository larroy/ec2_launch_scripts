#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Description"""

__author__ = 'Pedro Larroy'
__version__ = '0.1'

import os
import sys
from subprocess import check_call
import argparse
import logging
import boto3
import awsutils
import yaml
import logging
import getpass


def script_name() -> str:
    """:returns: script name with leading paths removed"""
    return os.path.split(sys.argv[0])[1]


def config_logging():
    import time
    logging.getLogger().setLevel(logging.INFO)
    logging.basicConfig(format='{}: %(asctime)sZ %(levelname)s %(message)s'.format(script_name()))
    logging.Formatter.converter = time.gmtime


def config_argparse() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="", epilog="")
    parser.add_argument('-c', '--config', type=str,
                        default='windows_instance.yaml',
                        help="config file")
    return parser


def main():
    config_logging()
    parser = config_argparse()
    args = parser.parse_args()
    ec2_resource = boto3.resource('ec2')
    with open(args.config) as f:
        create_instance_args = yaml.safe_load(f.read())
    print(create_instance_args)
    instances = ec2_resource.create_instances(**create_instance_args)
    ec2_resource.create_tags(
        Resources = [instance.id for instance in instances]
        , Tags = [
          {'Key': 'Name', 'Value': '{} windows'.format(getpass.getuser())}
        ]
    )


    awsutils.wait_for_instances(instances)
    hosts = [i.public_dns_name for i in instances]
    for host in hosts:
        logging.info("Waiting for host {}".format(host))
        awsutils.wait_port_open(host, 22, 300)
    logging.info("All done, the following hosts are now available: %s", hosts)


    return 0

if __name__ == '__main__':
    sys.exit(main())


