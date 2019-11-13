#!/usr/bin/env python3
from subprocess import check_output
from collections import namedtuple
import sys

PciDev = namedtuple('PciDev', ['dev', 'devclass', 'vendor', 'devid'])

NV_VENDOR_IDS=set(['1013', '10de'])

def parse_pci(pci):
    devices = []
    pci_lines = pci.splitlines()
    for l in pci_lines:
        # ['00:02.0', '0300:', '1013:00b8']
        fields = l.split()[:3]
        fields_clean = []
        fields_clean.append(fields[0])
        fields_clean.append(fields[1].rstrip(':'))
        fields_clean.extend(fields[2].split(':'))
        pcidev = PciDev(*fields_clean)
        devices.append(pcidev)
    num_gpu = 0
    for dev in devices:
        # https://pci-ids.ucw.cz/read/PD/03
        # 3Dcard or VGA from NVidia
        if (dev.devclass == '0300' or dev.devclass == '0302') and dev.vendor in NV_VENDOR_IDS:
            num_gpu += 1
    return num_gpu

def gpu_count():
    lspci = check_output(['lspci', '-n']).decode()
    return parse_pci(lspci)

def main():
    count = gpu_count()
    print("{} gpus.".format(count))
    if count:
        return 0
    else:
        return 1

if __name__ == '__main__':
    sys.exit(main())

