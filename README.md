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

## Dependencies
You need one of xorriso (`xorrisofs`), `mkisofs`, or `genisoimage` installed. The 
build script is plain POSIX `sh`, so bash is not required.

* Fedora, RHEL 8+ and rebuilds (AlmaLinux, Rocky, Oracle Linux): `sudo dnf install xorriso`.
  On RHEL it comes from the AppStream repository (it is not in the UBI container repos).
  `genisoimage` is no longer shipped in RHEL 10.
* Ubuntu, Debian, and derivatives: `sudo apt install xorriso`.
* Alpine: `apk add xorriso` (or `apk add cdrkit` for `mkisofs`).
* macOS: `brew install xorriso`.

## Usage

1. Clone this repository. (optional: maybe create and checkout your own branch?)
2. Modify the `meta-data` YAML file to specify your `instance-id` and `local-hostname`.
3. Modify the `user-data` YAML file -- according to [cloud-config syntax][4] -- to 
   specify a password and/or SSH keys. The cloud image determines the default user's 
   login name, but you can override that according to the [cloud-config documentation][4].
4. (optional) Commit your changes in git. This helps the build script name your ISO.
5. Build the ISO using `./build.sh`. You can either specify an output filename as the 
   first parameter (e.g. `./build.sh output-file.iso`), or you can let the script decide 
   on the filename. If you are working inside a git repository, the build script should 
   name your file after the branch and short commit hash, such as 
   `frost-init-20141228.dd648b2e.iso`.
6. If everything went well, attach the ISO file to your VM by methods 
   conventional to your virtualization hypervisor.
7. Boot the VM!

### Guest compatibility notes

* Fedora Cloud, RHEL/AlmaLinux/Rocky, Ubuntu, and Debian `generic`/`genericcloud` 
  images all run cloud-init, which picks up the `cidata` ISO automatically. (Debian's 
  `nocloud` images do *not* include cloud-init, despite the name.)
* Alpine's official cloud images default to [tiny-cloud][5] rather than cloud-init. It 
  reads this ISO and applies `local-hostname` and `ssh_authorized_keys`, but ignores 
  `password`, `chpasswd`, and `ssh_pwauth`. Use SSH keys, or the `cloudinit` variant 
  of the Alpine image, if you need password login.

## License

Some parts of this project are clearly not original. However, the bash script and 
any exemplary portions of the config files are hereby licensed under the MIT License; 
see `LICENSE`.

[1]: https://docs.cloud-init.io/en/latest/reference/datasources/nocloud.html
[2]: https://www.technovelty.org/linux/running-cloud-images-locally.html
[3]: https://projectatomic.io/blog/2014/10/getting-started-with-cloud-init/
[4]: https://docs.cloud-init.io/en/latest/reference/examples.html
[5]: https://gitlab.alpinelinux.org/alpine/cloud/tiny-cloud
