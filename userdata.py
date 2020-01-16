#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Uses ephemeral storage in AWS EC2 instances to automatically create a RAID device, which can be
mounted anywhere, note that ephemeral storage is not persistent after instance is stopped but it is
across reboots."""
import sys
import logging
import os
from subprocess import check_call, call, check_output, DEVNULL
import json
import re
import shutil
import urllib.request
import tempfile
from typing import List
import shutil
import time


def _scall(*args, **kwargs):
    """
    Call 'subprocess.call' silently
    """
    call(*args, **kwargs, stdout=DEVNULL, stderr=DEVNULL)


def write_userdata_complete(fname="/root/userdata_complete"):
    with open(fname,"w+") as f:
        f.write("")


def config_logging():
    def script_name() -> str:
        return os.path.split(sys.argv[0])[1]
    logging.getLogger().setLevel(logging.INFO)
    logging.basicConfig(format='{}: %(asctime)-15s %(message)s'.format(script_name()))


def _not(func):
    def not_func(*args, **kwargs):
        return not func(*args, **kwargs)
    return not_func


class BlockDeviceState:
    '''Cache for block devices from lsblk'''
    @staticmethod
    def blockdevices() -> List[object]:
        lsblk_j = check_output(["lsblk", "-J"]).decode('utf-8')
        blockdevices = json.loads(lsblk_j)['blockdevices']
        return blockdevices

    @staticmethod
    def _is_mounted(x) -> bool:
        if x['mountpoint']:
            return True
        if 'children' in x:
            for children in x['children']:
                if children['mountpoint']:
                    return True
        return False

    @staticmethod
    def _is_root(x) -> bool:
        def is_root_(x):
            return x['mountpoint'] == '/' or x['mountpoint'] == '[SWAP]'
        if is_root_(x):
            return True
        if 'children' in x:
            for children in x['children']:
                if is_root_(children):
                    return True
            return False

    @staticmethod
    def _dev_path(x) -> str:
        return '/dev/{}'.format(x['name'])

    def _partitions(blockdevices) -> List[object]:
        """
        :returns: list of /dev/[device][partition] strings
        """
        partitions = []
        for x in blockdevices:
            if 'children' in x:
                for child in x['children']:
                    if child['type'] == 'part':
                        partitions.append(_dev_path(child))
        return partitions


    def __init__(self):
        self.reload()

    def reload(self):
        self.blockdevices = BlockDeviceState.blockdevices()

    def ephemeral_devs(self) -> List[str]:
        ephemeral = list(filter(lambda x: not BlockDeviceState._is_root(x) and not BlockDeviceState._is_mounted(x) and x['type'] == 'disk',
            self.blockdevices))
        devs = map(BlockDeviceState._dev_path, ephemeral)
        return list(devs)

    def ephemeral_partitions(self) -> List[str]:
        partitions = []
        for b in self.blockdevices:
            if 'children' in b and not BlockDeviceState._is_root(b) and b['type'] == 'disk':
                for child in b['children']:
                    if child['type'] == 'part':
                        partitions.append(BlockDeviceState._dev_path(child))
        return partitions


def _clear_gpt(x):
    with open(x, "w+") as f:
        f.seek(0)
        f.write('\0' * 34 * 512)
        f.seek(0, 2)
        sz = f.tell()
        f.seek(sz - 34 * 512)
        f.write('\0' * 34 * 512)


def create_raid_partitions() -> List[str]:
    state = BlockDeviceState()
    for x in state.ephemeral_partitions():
        _scall(['umount', x])

    for x in state.ephemeral_devs():
        _scall(['umount', x])

    for x in state.ephemeral_devs():
        check_call(['dd','if=/dev/zero','of={}'.format(x),'bs=4096','count=1024'], stderr=DEVNULL, stdout=DEVNULL)
        logging.info("Partitioning %s", x)
        #check_call(f'sgdisk -z -o -n 1 -t 1:fd00 {x}'.split(), stderr=DEVNULL, stdout=DEVNULL)
        _clear_gpt(x)
        check_call(f'sgdisk -Z {x}'.split(), stdout=DEVNULL)
        time.sleep(1)
        check_call(f'sgdisk -o -n 1 -t 1:fd00 {x}'.split(), stdout=DEVNULL)
        time.sleep(1)

    # reload partitions
    call(['partprobe'])
    # wait for partitions to stabilize, otherwise they are not listed
    time.sleep(3)
    state.reload()
    return state.ephemeral_partitions()


def add_to_fstab(device, mount) -> None:
    fstab = []
    with open("/etc/fstab", "r") as f:
        for line in f:
            fields = re.split('\s+', line)
            device_field = fields[0]
            if device != device_field:
                fstab.append(line)
        fstab.append('{} {} ext4 noatime,discard 0 0'.format(device, mount))

    with tempfile.NamedTemporaryFile(delete=False, mode='w+') as f:
        f.writelines(fstab)
        f.write('\n')
        f.close()
        shutil.move('/etc/fstab', '/etc/fstab.bak')
        shutil.move(f.name, '/etc/fstab')


def raid_setup(raid_device, mount, level='0') -> bool:
    """Create raid device.
    :param raid_device: device for the raid, ex: /dev/md0
    :param mount: mount point, ex: /home
    :returns: True if the raid was created, False otherwise
    """
    logging.info("Raid setup, device: %s, mount point: %s", raid_device, mount)
    _scall(['umount', raid_device])
    # some instances mount the first ephemeral in /mnt
    _scall(['umount', '/mnt'])
    _scall(["mdadm", "--stop", raid_device])

    state = BlockDeviceState()
    if len(state.ephemeral_devs()) < 1:
        logging.error("raid_setup: Need at least one ephemeral drive that is not in use to configure the raid, aborting.")
        return False

    partitions = create_raid_partitions()
    logging.info("Created partitions %s", partitions)
    state.reload()

    # Create raid
    cmd = ['mdadm', '--create', '--force', '--verbose', raid_device, '--level={}'.format(level), '-c256K',
        '--raid-devices={}'.format(len(partitions))]
    cmd.extend(partitions)
    check_call(cmd, stdout=DEVNULL)

    check_call("mdadm --detail --scan > /etc/mdadm.conf", shell=True, stdout=DEVNULL)

    # format fs
    check_call(['mkfs', '-q',  '-t', 'ext4', '-F', '-m', '0', raid_device])

    add_to_fstab(raid_device, mount)
    os.makedirs(mount, exist_ok=True)
    check_call(['mount', mount])
    return True


def raid_setup_file_preserving(raid_dev, mount_point, level='0'):
    assert mount_point.startswith('/')
    with tempfile.TemporaryDirectory() as tmpdir:
        if os.path.exists(mount_point):
            check_call(['rsync', '-vaP', os.path.join(mount_point,''), tmpdir])
        success = raid_setup(raid_dev, mount_point, level)
        if success and os.path.exists(mount_point):
            check_call(['rsync', '-vaP', os.path.join(tmpdir, ''), mount_point])


def set_hostname() -> None:
    ip = urllib.request.urlopen('http://169.254.169.254/latest/meta-data/public-ipv4').read().decode()
    ip = ip.replace('.', '-')
    with open('/etc/hostname', 'w+') as fh:
        fh.write(ip)
        fh.write('\n')
    check_call(['hostname', '-F', '/etc/hostname'])


def main():
    config_logging()
    logging.info("Starting userdata.py")
    raid_setup_file_preserving('/dev/md0', '/mnt/ephemeral', '0')
    set_hostname()
    write_userdata_complete()
    logging.info("userdata.py finished")
    return 0


if __name__ == '__main__':
    sys.exit(main())
