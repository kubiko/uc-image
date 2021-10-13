# Custom Ubuntu Core image builder
This is command line tool for building Ubuntu Core images. It does follow ubuntu-image syntax. In addition it supports build of images in format for various flash tools and SoCs.

## Supported flash tools, SoCs:
- NXP: uuu flash tool
- Qualcomm: fastboot, qdl, QFIL
- Mediatek: native flash tool, fastboot
- Ambarella: AmbaUSB

## Extra features:
- --use-android-fs-tools: use Android file system tools (make_ext4fs) to generate sparse files compatible with Android flash tools
- --build-seed-image: generate reflash image bundle (all the boot asset files, plus compressed ubuntu-seed partition image)
- --disk-info: File to be used as .disk/info on the image's rootfs
- --build-raw: do not convert created images to sparse
- Auto detection of Ambarella build to generate elf files to be used by Ambarella AmbaUSB flash tools.

## Obsolete customisation options for Ubuntu Core 16/18
- --network-config:
- --disable-console-conf: Disable console conf in the image
- --netplan-config: Include default netplan config in the image
- --auto-import-assertion: Include auto-import-assertion file to the image
- --hooks-directory: Hooks to be invoked at image build time
- --overlay: Custom overlay to be added to the image
- --backdoor: Create backdoor in the created image
- --disable-ssh-server: disable ssh server
- --journald-storage-persistent: forward journald to persistent storage
- --seed-root-ssh-authorized-keys:  populate root's authorized_keys (/root/.ssh/authorized_keys) with passed public key(s)
- --enable-early-getty: Forcefull disabling of console conf and early enablement of getty
- --set-hostname: set initial hostname to be used at first boot
