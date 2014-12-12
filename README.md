Cloud Init ISO
==============

Many premade cloud images (e.g. Fedora Cloud, Ubuntu Cloud) use some form of 
cloud-init to set instance/user metadata, such as hostnames and SSH keys. This 
works well when used in a cloud infrastructure such as EC2 or OpenStack that can 
seed this data, but not so well when used for local VMs, or an out-of-the-box 
XenServer installation.

However, [cloud-init supports an CD/ISO datasource][1], which can be loaded 
whether running the machine locally in KVM, VirtualBox, or on a XenServer host. 

This repository and guide aims to make this task a lot easier by pre-seeding a 
template and script. It draws heavily on existing resources ([2][2], [3][3]).

## Usage

1. Clone this repository.
2. Modify the `meta-data` YAML file to specify your `instance-id` and `local-hostname`.
3. Modify the `cloud-config` YAML file to specify a password and/or SSH keys; 
   the cloud image determines the default user's login name 
   (e.g. `fedora` in Fedora Cloud).
4. Verify that you have the dependency `genisoimage`. In RHEL/CentOS/Fedora, 
   `sudo yum install genisoimage`; in Ubuntu/Debian, `sudo apt-get install genisoimage`.
5. Build the ISO using `./build.sh`.
6. If everything went well, attach the `init.iso` file to your VM by methods 
   conventional to your virtualization hypervisor.
8. Boot the VM!


[1]: http://cloudinit.readthedocs.org/en/latest/topics/datasources.html#no-cloud
[2]: https://www.technovelty.org/linux/running-cloud-images-locally.html
[3]: http://www.projectatomic.io/blog/2014/10/getting-started-with-cloud-init/

