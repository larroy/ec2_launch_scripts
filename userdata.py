#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import sys
import logging
import os
from subprocess import check_call, call, check_output
import json
import re
import shutil

def write_userdata_complete(fname="/tmp/userdata_complete"):
    with open(fname,"w+") as f:
        f.write("")

def config_logging():
    def script_name() -> str:
        return os.path.split(sys.argv[0])[1]
    logging.getLogger().setLevel(logging.DEBUG)
    logging.basicConfig(format='{}: %(asctime)-15s %(message)s'.format(script_name()))

def _not(func):
    def not_func(*args, **kwargs):
        return not func(*args, **kwargs)
    return not_func

def raid_setup(raid_device, mount, level='0') -> bool:
    """Create raid device.
    :param raid_device: device for the raid, ex: /dev/md0
    :param mount: mount point, ex: /home
    :returns: True if the raid was created, False otherwise
    """
    logging.info("Raid setup, device: %s, mount point: %s", raid_device, mount)
    call(['umount', raid_device])
    # some instances mount the first ephemeral in /mnt
    call(['umount', '/mnt'])
    call(["mdadm", "--stop", raid_device])
    lsblk_j = check_output(["lsblk", "-J"]).decode('utf-8')
    logging.debug("lsblk -J output: %s", lsblk_j)
    blockdevices = json.loads(lsblk_j)['blockdevices']
    def is_mounted(x):
        if x['mountpoint']:
            return True
        if 'children' in x:
            for children in x['children']:
                if children['mountpoint']:
                    return True
        return False

    def is_root(x):
        def is_root_(x):
            return x['mountpoint'] == '/' or x['mountpoint'] == '[SWAP]'
        if is_root_(x):
            return True
        if 'children' in x:
            for children in x['children']:
                if is_root_(children):
                    return True
        return False

    roots = list(map(lambda x: x['name'],filter(is_root, blockdevices)))
    root_devices = set(roots)
    ephemeral = list(filter(lambda x: not is_root(x) and not is_mounted(x), blockdevices))
    ephemeral_devices = list(map(lambda x: '/dev/{}'.format(x['name']), ephemeral))

    if len(ephemeral) < 1:
        logging.error("raid_setup: Need at least one ephemeral drive that is not in use to configure the raid, aborting.")
        return False

    logging.info("Ephemeral drives %s, roots: %s root_devices: %s", ephemeral_devices, roots, root_devices)
    for e in ephemeral:
        if is_mounted(e):
            raise RuntimeError("Ephemeral {} is mounted, aborting".format(e))

    logging.info("Creating raid in drives %s", ephemeral_devices)
    for ephemeral in ephemeral_devices:
        call(['umount', ephemeral])
        # erase first blocks
        check_call(['dd','if=/dev/zero','of={}'.format(ephemeral),'bs=4096','count=1024'])

    # reload partitions
    call(['partprobe'])

    # Create raid
    cmd = ['mdadm', '--create', '--force', '--verbose', raid_device, '--level={}'.format(level), '-c64K',
        '--raid-devices={}'.format(len(ephemeral_devices))]
    cmd.extend(ephemeral_devices)
    check_call(cmd)

    check_call("mdadm --detail --scan > /etc/mdadm.conf", shell=True)

    # format fs
    check_call(['mkfs', '-t', 'ext4', '-F', '-m', '0', raid_device])

    # add to fstab
    fstab = []
    with open("/etc/fstab", "r") as f:
        ephemerals = set(ephemeral_devices)
        for line in f:
            fields = re.split('\s+', line)
            device = fields[0]
            if not device in ephemeral_devices and device != raid_device:
                fstab.append(line)
        fstab.append('{} {} ext4 noatime,discard 0 0'.format(raid_device, mount))

    with open("/etc/fstab", "w") as f:
        f.writelines(fstab)
        f.write('\n')

    check_call(['mount', mount])
    return True


def raid_setup_file_preserving(raid_dev, mount_point, level='0'):
    assert mount_point.startswith('/')
    check_call(['rsync', '-vaP', mount_point, '/tmp'])
    raid_setup(raid_dev, mount_point, level)
    check_call(['rsync', '-vaP', '/tmp{}/'.format(mount_point), mount_point])
    shutil.rmtree('/tmp{}'.format(mount_point))


def main():
    config_logging()
    logging.info("Starting userdata.py")
    raid_setup_file_preserving('/dev/md0', '/home', '5')
    write_userdata_complete()
    logging.info("userdata.py finished")
    return 0

if __name__ == '__main__':
    sys.exit(main())

