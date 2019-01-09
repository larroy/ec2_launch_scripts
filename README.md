# A nifty tool to easily launch and provision development instances in EC2

I start and terminate instances often for software development. This is a tool which makes it easy
and quick to launch an instance configured and provisioned so you can start using it right away
without manual configuration.

A nice feature is that it will use the ephemeral drives avaiable on the instance and create a raid
volume `/dev/md0` which will be mounted in `/home`. Many instance types have very fast local storage
such as SSD disks and NVMe drives. Having the home folder in a raid0 of ephemeral drives makes
working with the storage much faster than the default EBS root volume. This is done by
`userdata.py`.

# Dependencies

You would need Python3, boto3 and ansible installed.
You can install them with the following commands:

```
pip3 install -r requirements.txt
```

You can copy the files that you want into `homedir/` which will populate your home in the instance.
For example you might want to copy your .ssh folder, shell and editor configuration there.
  

# Run it!

You should [configure your AWS credentials](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html)
and have EC2 permissions:

Edit `launch_template.yml` to your needs and launch!

You can choose your ami depending on your region. For example using the [ubuntu ami locator](https://cloud-images.ubuntu.com/locator/ec2/).
And choose your [instance type](https://www.ec2instances.info) depending on your needs.

```
$ ./launch.py
instance_name [worker-piotr]:
instance_type [m1.xlarge]:
(public) ssh_key_file [/home/piotr/.ssh/id_rsa.pub]:
ami [ami-58d7e821]:
user name [piotr]:
[...]
```

After a few minutes the instance is created and provisioned and the hostname is printed on the
output so you can ssh to it.

# GPU instances
For gpu instances you can run `nvidia_setup.sh` once.
Then you can check that the GPU is accessible from docker running:
```
nvidia-docker run -ti nvidia/cuda:9.1-cudnn7-devel nvidia-smi
```

Now you are ready to install your deep learning framework of choice.

# How it works?

The `launch.py` script is just a bunch of boto3 calls which configure the security groups, ssh key
and instance. The initialization is done with [cloud init](https://cloudinit.readthedocs.io/en/latest/index.html)
using the `cloud-init` file and `userdata.py` which configures the raid of ephemerals.

After this is done, [ansible](https://www.ansible.com/) is used to provision the instance by
installing software such as docker etc.

# Contributing

Feel free to improve and modify the scripts and send any changes as a PR.
