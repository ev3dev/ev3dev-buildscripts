ev3dev-buildscripts
===================

These are the scripts used to compile the ev3dev kernel. Originally it also
included scripts to bootstrap a root file system and create a disk image.
Those scripts have evolved into the [brickstrap] package.

**NOTE:** The instructions below are for ev3dev-buster. If you want to build
a kernel for ev3dev-stretch, please use the [ev3dev-stretch branch].

[ev3dev-stretch branch]: https://github.com/ev3dev/ev3dev-buildscripts/tree/ev3dev-stretch

System Requirements
-------------------
* Ubuntu LTS (can be run in a [virtual machine](https://www.virtualbox.org/)
  or with [Windows Subsystem for Linux](https://msdn.microsoft.com/en-us/commandline/wsl/install_guide))
* User account with `sudo` enabled
* Packages:

        # If you haven't already added the ev3dev.org repository...
        sudo apt-add-repository ppa:ev3dev/tools
        sudo apt-get update
        # then install required packages
        sudo apt-get install git build-essential ncurses-dev fakeroot bc \
        u-boot-tools lzop flex bison libssl-dev gcc-arm-linux-gnueabihf-8.3


Scripts
-------

`build-kernel`               Used to build the kernel.

`defconfig`                  Used to manage the `*_defconfig` file and
                             your current local configuration (`.config`).

`menuconfig`                 Runs the menu configuration tool for the
                             kernel configuration.


First time kernel build
-----------------------

1.  Create a working directory somewhere. For this tutorial, we are using
    `~/work`. The build scripts will generate extra subdirectories here
    so we suggest creating a new directory instead of using an existing one.

        ~ $ mkdir work
        ~ $ cd work

2.  Clone this repo and also the `ev3-kernel` repo (or `rpi-kernel` or `bb.org-kernel`),
    then make sure the lego drivers submodule is up to date (we don't always
    update the submodule commit in the kernel repo, so you have to pull manually
    to get the most recent commits).

        ~/work $ git clone git://github.com/ev3dev/ev3dev-buildscripts
        ~/work $ git clone --recursive --depth 150 git://github.com/ev3dev/ev3-kernel
        ~/work $ cd ev3-kernel/drivers/lego
        ~/work/ev3-kernel/drivers/lego $ git pull origin ev3dev-buster
        ~/work/ev3-kernel/drivers/lego $ cd -

3.  Change to the `ev3dev-buildscripts` directory and have a look around.

        ~/work $ cd ev3dev-buildscripts
        ~/work/ev3dev-buildscripts $ ls
        boot.cmd        build-kernel  LICENSE    menuconfig  setup-env
        build-boot-scr  defconfig     local-env  README.md

4.  Create a `local-env` to make use of all of your processing power. See the
    [Faster Builds and Custom Locations](#faster-builds-and-custom-locations)
    section below for more about this file.

        ~/work/ev3dev-buildscripts $ echo "export EV3DEV_MAKE_ARGS=-j4" > local-env

5.  Now we can compile the kernel.

        ~/work/ev3dev-buildscripts $ ./build-kernel

    For Raspberry Pi and BeagleBone Black we need to set an environment variable.

        # Rapsberry Pi 1
        EV3DEV_KERNEL_FLAVOR=rpi ./build-kernel
        # Raspberry Pi 2
        EV3DEV_KERNEL_FLAVOR=rpi2 ./build-kernel
        # BeagleBoard
        EV3DEV_KERNEL_FLAVOR=bb.org ./build-kernel

6.  That's it!  

    TODO: add instructions on how to modify uEnv.txt to use uImage file.
 
    For now, see [Sharing Your Kernel](#sharing-your-kernel) for how to create
    a debian package to install the kernel you just built.


Faster Builds and Custom Locations
----------------------------------

By default the locations of the kernel source tree and the toolchain used
to build the kernel are expected to be in certain directories relative to
the ev3dev-buildscripts repo directory.

You can override these locations by creating a file called `local-env`
in the ev3dev-buildscripts directory or `~/.ev3dev-env` (in your home directory).
It should look like this:

    #!/bin/sh
    
    export EV3DEV_MAKE_ARGS=-j4
    
    # override any EV3DEV_* variables from setup-env script.
    #export EV3DEV_XXX=/custom/path
    #export EV3DEV_MERGE_CMD="kdiff3 \$file1 \$file2"
    #export EV3DEV_MERGE_CMD="meld \$file1 \$file2"

The `-j4` is for faster builds. It allows make to compile files in
in parallel. You should replace 4 with the number of processor cores that
you want to devote to building the kernel.

You can use custom paths to make the `build-kernel` script automatically
install the kernel and modules directly on the EV3! First, you need to
mount the EV3 root file system. You can use nfs or sshfs (check the
[wiki] on how to do this). Then just set the appropriate paths in your
`local-env` like this:

    # replace `/mnt/ev3dev-root` with your actual mount point
    export EV3DEV_INSTALL_KERNEL=/mnt/ev3dev-root/boot/flash
    export EV3DEV_INSTALL_MODULES=/mnt/ev3dev-root


Managing the Kernel Configuration
---------------------------------

When you run `./build-kernel` if no existing kernel configuration exists
the default configuration is loaded from `arch/arm/configs/ev3dev_defconfig`.

If you make changes to your local kernel configuration that you want to merge
into the default configuration, run `./defconfig update`. It will use the
merge tool specified by the `EV3DEV_MERGE_CMD` environment variable.

If you have an existing kernel configuration, you will want to check for changes
to the default configuration each time you merge or checkout a branch. You can
call `./defconfig load` to wipe out your local configuration and load the
default configuration or you can call `./defconfig merge` to merge the
default configuration into your existing local configuration.

If you are forgetful or lazy or just want this to happen automatically, you can
set up hooks in your git repo. For example, you could save the following file as
both `.git/hooks/post-merge` and `.git/hooks/post-checkout` and you will
be prompted to merge the default configuration into your local configuration
whenever you merge or checkout a branch. In you followed the tutorial above,
`<path-to-ev3dev-buildscripts-repo>` would be `~/work/ev3dev-buildscripts`.

    #!/bin/sh
    
    <path-to-ev3dev-buildscripts-repo>/defconfig merge


Sharing Your Kernel
-------------------

Want to send your custom kernel to someone so that they can use it? Never fear,
there is an easy way to do that - using Debian packaging.

First, we want to set a kernel option so that our friends will know what kernel
they are running. Run `./menuconfig` and set this option:

    General setup --->
      (-your-name-ev3) Local version - append to kernel release

Make sure to include the '-' prefix in `-your-name` on the *Local version*.
And, of course, substitute something like your github user name for *your-name*.
It is also important that the kernel release ends with `-ev3` so that
`flash-kernel` will recognize it as a "good" kernel and install it automatically.

Then, we build a Debian package.

    ~/work/ev3dev-buildscripts $ ./build-kernel bindeb-pkg KDEB_PKGVERSION=1
    ...
    <lots-of-build-output>
    ...
    ~/work/ev3dev-buildscripts $ ls ./build-area/*.deb
    ./build-area/linux-headers-3.16.7-ckt9-5-ev3dev-your-name-ev3_1_armel.deb
    ./build-area/linux-image-3.16.7-ckt9-5-ev3dev-your-name-ev3_1_armel.deb
    ./build-area/linux-libc-dev_1_armel.deb

Now, send the `linux-image-*` file to your friend with these instructions:

* Copy the `.deb` file to your EV3
* Install the package
* Reboot the EV3

Example:

    user@host ~ $ scp linux-image-*.deb otheruser@ev3dev:~
    user@host ~ $ ssh otheruser@ev3dev
    otheruser@ev3dev:~$ sudo dpkg --install ~/linux-image-*.deb
    otheruser@ev3dev:~$ sudo reboot

Common Errors
-------------

* If you see this error...

        ERROR: ld.so: object 'libfakeroot-sysv.so' from LD_PRELOAD cannot be preloaded (wrong ELF class: ELFCLASS64): ignored.
    
    ...just ignore it. It is normal (a side effect of cross-compiling).

* If you see an error related to `asm/bitsperlong.h` like this:

        ...
          Generating include/generated/mach-types.h
          CC      kernel/bounds.s
        In file included from /home/user/ev3-kernel/arch/arm/include/asm/types.h:4:0,
                         from /home/user/ev3-kernel/include/linux/types.h:4,
                         from /home/user/ev3-kernel/include/linux/page-flags.h:8,
                         from /home/user/ev3-kernel/kernel/bounds.c:9:
        /home/user/ev3-kernel/include/asm-generic/int-ll64.h:11:29: fatal error: asm/bitsperlong.h: No such file or directory
        compilation terminated.
        make[2]: *** [kernel/bounds.s] Error 1
        make[1]: *** [prepare0] Error 2
        make: *** [sub-make] Error 2

    Then you need to clean your kernel source tree like this:

         user@host ~/ev3-kernel $ git clean -dfX

[brickstrap]: https://github.com/ev3dev/brickstrap
[wiki]: https://github.com/ev3dev/ev3dev/wiki
