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
- `--preseed`                Create pressed image. The tool has to run as root.
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

- `--prepared-image`         Build from what `snap prepare-image <model> <dir>` wrote, instead of running it. The model comes from the seed. The directory is copied, never written to.
- `--allow-snapd-kernel-mismatch` Passed through to `snap prepare-image`, for a kernel snap which does not declare the snapd it needs.
- `--build-disk-image`       Also build a whole disk image of each gadget volume, see below.

## Bootloaders
Images are built for u-boot, lk and grub, which is what the gadget's `bootloader` says.

## Whole disk images
`--build-disk-image` builds `<volume>.img` for each gadget volume next to the partition images: the partition table and all content, at the offsets of `gadget.yaml`. It works for `gpt` and `mbr` volumes, skips `emmc` ones, which describe hardware partitions, and does not go with `--build-tar-seed`, `--build-dir-seed` or Ambarella amboot.

As with ubuntu-image, `ubuntu-boot`, `ubuntu-save` and `ubuntu-data` get space on the disk but no partition, as the install creates them.

To run such an image in qemu, with UEFI for a grub gadget:
```
qemu-system-x86_64 -machine q35 -accel kvm -m 2048 -nographic \
  -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd \
  -drive if=pflash,format=raw,file=OVMF_VARS_4M.fd \
  -drive file=pc.img,format=raw,if=virtio
```
`OVMF_VARS_4M.fd` is a writable copy of the one in `/usr/share/OVMF`.

## Ubuntu Core 16/18 support
Support for Ubuntu Core 16/18 is no more supported by uc-image.
