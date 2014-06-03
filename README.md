If you just want to use ev3dev, please see the
[main ev3dev repository](https://github.com/mindboards/ev3dev).

If you want to build the ev3dev kernel or root file system, read on.

ev3dev-rootfs
=============

These are the scripts used to compile the ev3dev kernel and build the root
file system.


System Requirements
-------------------
* Debian or derivative OS (Ubuntu, Mint, etc.)
* User account with ```sudo``` enabled

Scripts
-------

`build-kernel`               Used to build the kernel.

`defconfig`                  Used to manage the ev3dev_defconfig file and
                             your current local configuration.

`install-kernel-build-tools` Installs the prerequisite tools required
                             to build the kernel.

`menuconfig`                 Runs the menu configuration tool for the
                             kernel configuration.


First time kernel build
-----------------------

1.  If you don't have `git` already, then we need to install it.

        ~ $ sudo apt-get install git

2.  Create a working directory somewhere. For this tutorial, we are using
    `~/work`. The build scripts will generate extra subdirectories here
    so we suggest creating a new directory instead of using an existing one.

        ~ $ mkdir work
        ~ $ cd work

3.  Clone the kernel and root file system repos.

        ~/work $ git clone git://github.com/mindboards/ev3dev-kernel
        ~/work $ git clone git://github.com/mindboards/ev3dev-rootfs

4.  Change to the `ev3dev-rootfs` director and have a look around.

        ~/work $ cd ev3dev-rootfs
        ~/work/ev3dev-rootfs $ ls
        build_ev3dev_setup          menuconfig         sdcard-img-mount
        build_extras                multistrap.conf    sdcard-img-populate
        build-kernel                README.md          update-defconfig
        install-kernel-build-tools  rootfs-create
        LICENSE                     sdcard-img-create


5.  Now we need to install the required tool. TO do this, just run the
    `install-kernel-build-tools` script. (You only need to run this once.)

        ~/work/ev3dev-rootfs $ ./install-kernel-build-tools

6.  Create a `local-env` to make use of all of your processing power. See the
    [Faster Builds and Custom Locations](#faster-builds-and-custom-locations)
    section below for more about this file.

        ~/work/ev3dev-rootfs $ echo "#!/bin/sh
        
        export EV3DEV_MAKE_ARGS=-j4" > local-env

7.  Now we can compile the kernel.

        ~/work/ev3dev-rootfs $ ./build_kernel

8.  That's it! The uImage and kernel modules you just built are saved in
    `../dist`. You just need to copy the files to your
    already formatted SD card.

        ~/work/ev3dev-rootfs $ cd ../dist
        ~/work/dist $ cp uImage <path-to-boot-partition>/uImage
        ~/work/dist $ sudo cp -r lib/ <path-to-file-system-partition>


Faster Builds and Custom Locations
----------------------------------

By default the locations of the kernel source tree and the toolchain used
to build the kernel are expected to be in certain directories relative to
the ev3dev-rootfs repo directory.

You can override these locations by creating a file called `local-env`
in the ev3dev-rootfs directory or `~/.ev3dev-env` (in your home directory).
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


Managing the Kernel Configuration
---------------------------------

When you run `./build-kernel` if no existing kernel configuration exists
the default configuration is loaded from `arch/arm/configs/ev3dev_defconfig`.

If you make changes to your local kernel configuration that you want to merge
into the default configuration, run `./defconfig update`. If you want to
selectively merge changes, run `./defconfig update -i` which will open the
merge tool specified by the EV3DEV_MERGE_CMD environment variable.

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
`<path-to-ev3dev-rootfs-repo>` would be `~/work/ev3dev-rootfs`.

    #!/bin/sh
    
    <path-to-ev3dev-rootfs-repo>/defconfig merge


Sharing Your Kernel
-------------------

Want to send your custom kernel to someone so that they can use it? Never fear,
there is an easy way to do that - using Debian packaging.

First, we need to change a couple kernel options to add some version info so
that our friends will know what kernel they are running. Run `./menuconfig`
and set the following options:

    General setup --->
      (-your-name) Local version - append to kernel release
      [*] Automatically append version information to the version string

Make sure to include the '-' prefix in `-your-name` on the _Local version_.
And, of course, substitute something like your github user name for _your-name_.
Also, I don't recommend leaving the second option enabled during regular
development, otherwise every time you make a commit, you will have to reload the
kernel on your EV3 even if you only made changes to modules.

Now, make sure that your git repo is clean (or your kernel version will say
_dirty_).

    ~/work/ev3dev-kernel $ git status
    # On branch awesomeness
    nothing to commit, working directory clean

Then, we build a Debian package (with a crazy huge file name).

    ~/work/ev3dev-rootfs $ ./build-kernel deb-pkg KDEB_PACKAGEVERSION=1
    ...
    <lots-of-build-output>
    ...
    ~/work/ev3dev-rootfs $ ls ../*.deb
    ../linux-headers-3.3.0-ev3dev-00.01.02-your-name-g04254fb_1_armel.deb
    ../linux-image-3.3.0-ev3dev-00.01.02-your-name-g04254fb_1_armel.deb
    ../linux-libc-dev_1_armel.deb

Now, send the `linux-image-i*` file to your friend with these instructions:

* Copy the `.deb` file to your EV3
* Install the package
* Overwrite the existing uImage file on the FAT partition with the new one
* Reboot the EV3

Example:

    user@host ~ $ scp linux-image-*.deb root@ev3dev:/tmp
    user@host ~ $ ssh root@ev3dev
    root@ev3dev:~# dpkg --install /tmp/linux-image-*.deb
    root@ev3dev:~# cp /boot/uImage-3.3.0-ev3dev-00.01.02-your-name-g04254fb /media/mmc_p1/uImage 
    root@ev3dev:~# reboot


