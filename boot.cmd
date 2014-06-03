run loadimage
fatload mmc 0 ${filesysaddr} uInitrd
setenv bootargs mem=${memsize} console=${console} initrd=${filesysaddr},${filesyssize} root=/dev/ram rw rootwait lpj=747520 splash fbcon=font:ProFont6x11 plymouth.ignore-serial-consoles break=premount
bootm ${loadaddr} ${filesysaddr}

