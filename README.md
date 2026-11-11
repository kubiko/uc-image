# Custom Ubuntu Core image builder
This is command line tool for building Ubuntu Core images. It does follow ubuntu-image syntax. In addition, it supports building images in formats for various flash tools and SoCs.

## Supported flash tools, SoCs:
- UEFI: whole disk images for qemu and dd
- NXP: uuu flash tool
- Qualcomm: fastboot, qdl, QFIL
- Mediatek: native flash tool, fastboot
- Ambarella: AmbaUSB

## Standard features:
- `-h`, `--help`             Show this help message and exit"
- `--snap`                   Install an extra snap, the snap argument can include additional information about the track|risk channel/branch with the following syntax: <snap>=<track|channel/branch>
                             Examples: `--snap go=1.14|stable`
                                      `--snap avahi.snap`
- `--revisions`              Specify a subuntu-core-image.revisions file referencing the exact revisions of the provided snaps which should be installed. `ubuntu-core-image.manifest` and `ubuntu-core-image.revisions` are auto-generated for each build in the `manifest/` subdirectory of the output directory.
- `--preseed`                Create preseeded image. Only `snap prepare-image --preseed` runs as root, with sudo, see below.
- `--preseed-sign-key`       Name of the key to use to sign preseed assertion.
- `--validation`             Control of the validation sets, choose 'ignore' or 'enforce'.
- `--preseed-sysfs-overlay`  Overlay of sysfs to be used when building presseded image. This is required when building images with specific hw interfaces.
- `--auto-import-assertion`  Auto import assertion file to be included in the root of the main writable partition. This assertion is imported once the system is fully seeded. A passed file does not need to have the correct file name; it will be renamed.
- `--sector-size`            Logical sector size of the target storage, 512 or 4096. Use 4096 for 4k storage such as UFS.
- `--build-raw`              Build raw disk images, instead of sparse ones.
- `-O`, `--output-dir`       Output directory.
- `-w`, `--workdir`          Working directory.
- `-d`, `--debug`            Print debug
- `-dd`                      Print verbose debugs
- `-v`, `--version`          Pring version info
- `--disk-info`              File to be used as .disk/info on the image's rootfs. This file can contain useful information about the target image, like image identification data, system name, build timestamp, etc.

- `--prepared-image`         Build from what `snap prepare-image <model> <dir>` wrote, instead of running it. The model comes from the seed. The directory is copied, never written to. It does not go with `--preseed`, a prepared image is preseeded when it is prepared.
- `--allow-snapd-kernel-mismatch` Passed through to `snap prepare-image`, for a kernel snap which does not declare the snapd it needs.
- `--build-disk-image`       Also build a whole disk image of each gadget volume, see below.
- `--image-size`             Size of the whole disk images, implies `--build-disk-image`, see below.
- `--sparse-disk-image`      Convert the whole disk images to sparse images, implies `--build-disk-image`, see below.
- `--no-ab-support`          Switch off A/B slot support, see below.

## Preseeded images and root
`snap prepare-image --preseed` mounts the snaps and chroots into them, so it needs root. That is the only part of the build which runs as root: uc-image runs it with sudo, as `uc-image.preseed-stage`, which prepares the image into the work directory and gives it back to the user. The rest of the build runs as the user and uses the work directory as it is, nothing is copied, so the user owns all it creates, as with an image which is not preseeded. `fakeroot` makes the files root's in the file system images.

Started with sudo, `sudo uc-image --preseed ...`, the build goes on as the user who ran sudo once the image is prepared, and one which does not preseed runs as that user from the start.

For no password to be asked, allow the root part in `/etc/sudoers`, with `visudo`:
```
<user> ALL=(root) NOPASSWD: /snap/bin/uc-image.preseed-stage
```
This is no security boundary: preseeding runs the snapd of the image as root, which can be a local snap, so whoever may run it may run anything as root. `--preseed-sign-key` takes the key from root's keyring, `/root/.snap/gnupg`, as before.

Output and work directories which a build as root left are not removed, uc-image asks to remove them with sudo.

## Bootloaders
Images are built for u-boot, lk and grub, which is what the gadget's `bootloader` says.

## Whole disk images
`--build-disk-image` builds `<volume>.img` for each gadget volume next to the partition images: the partition table and all content, at the offsets of `gadget.yaml`. It works for `gpt` and `mbr` volumes, skips `emmc` ones, which describe hardware partitions, and does not go with `--build-tar-seed`, `--build-dir-seed` or Ambarella amboot.

As with ubuntu-image, `ubuntu-boot`, `ubuntu-save` and `ubuntu-data` get space on the disk but no partition, as the install creates them. An image with A/B slots has all of its partitions, as they are not created on the device.

A disk image is as big as its content, plus 1 MiB or more for the backup GPT. `--image-size` makes it bigger, with the syntax of ubuntu-image: a size in bytes or with a `K`, `M` or `G` suffix, for all volumes, or per volume, by name or index in `gadget.yaml`, e.g. `--image-size 4G` or `--image-size pc:8G,1:512M`. A size with no volume is for the volumes not named, e.g. `--image-size 512M,pc:8G`. A size is rounded up to whole 4 KiB, and one smaller than the content needs is ignored, with a warning.

`--sparse-disk-image` converts each disk image, once it is built, to a sparse image, as the partition images are, which is smaller to store and download, and which fastboot can flash. qemu and dd need a raw image, which `simg2img <volume>.img <volume>.raw` gives back.

To run such an image in qemu, with UEFI for a grub gadget:
```
qemu-system-x86_64 -machine q35 -accel kvm -m 2048 -nographic \
  -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd \
  -drive if=pflash,format=raw,file=OVMF_VARS_4M.fd \
  -drive file=pc.img,format=raw,if=virtio
```
`OVMF_VARS_4M.fd` is a writable copy of the one in `/usr/share/OVMF`.

## A/B slots
A gadget with the `system-slot-a` role gets an image with A/B slots: `ubuntu-system.img`, `ubuntu-apps.img` and, on u-boot, `ubuntu-boot-state.img`, as `snap prepare-image` wrote them, with `manifest/ab-slots.json` listing the snaps they hold. `snap prepare-image` has to come from a snapd which knows the slot roles, so run it first and pass `--prepared-image` if the one on the host does not. It writes everything that matters; only the file system images of the other structures are built here.

`--auto-import-assertion` works as usual, and `--set-to-factory-reset` is refused.

A/B support is all in `usr/lib/uc-image/ab-slots.sh`, which the main script calls for a gadget with the slots only. There are three ways to switch it off, each of which makes a gadget with the slots an error:
- `--no-ab-support` for a build
- `UC_IMAGE_AB_SUPPORT=off` in the environment
- leaving the file out of the snap: `stage: [-usr/lib/uc-image/ab-slots.sh]` in the `glue` part

## Ubuntu Core 16/18 support
Support for Ubuntu Core 16/18 is no more supported by uc-image.
