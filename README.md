# Custom Ubuntu Core image builder
This is command line tool for building Ubuntu Core images. It does follow ubuntu-image syntax. In addition, it supports building images in formats for various flash tools and SoCs.

## Supported flash tools, SoCs:
- NXP: uuu flash tool
- Qualcomm: fastboot, qdl, QFIL
- Mediatek: native flash tool, fastboot
- Ambarella: AmbaUSB

## Standard features:
- `-h`, `--help`             Show this help message and exit"
- `--snap`                   Install an extra snap, the snap argument can include additional information about the track|risk channel/branch with the following syntax: <snap>=<track|channel/branch>
                             Examples: `--snap go=1.14|stable`
                                      `--snap avahi.snap`
- `--revisions`              Specify a subuntu-core-image.revisions file referencing the exact revisions of the provided snaps which should be installed. `seeds.manifest` and `ubuntu-core-image.revisions` are auto-generated for each build.
- `--preseed`                Create pressed image. The tool has to run as root.
- `--preseed-sign-key`       Name of the key to use to sign preseed assertion.
- `--validation`             Control of the validation sets, choose 'ignore' or 'enforce'.
- `--preseed-sysfs-overlay`  Overlay of sysfs to be used when building presseded image. This is required when building images with specific hw interfaces.
- `--auto-import-assertion`  Auto import assertion file to be included in the root of the main writable partition. This assertion is imported once the system is fully seeded. A passed file does not need to have the correct file name; it will be renamed.
- `--build-raw`              Build raw disk images, instead of sparse ones.
- `-O`, `--output-dir`       Output directory.
- `-w`, `--workdir`          Working directory.
- `-d`, `--debug`            Print debug
- `-dd`                      Print verbose debugs
- `-v`, `--version`          Pring version info
- `--disk-info`              File to be used as .disk/info on the image's rootfs. This file can contain useful information about the target image, like image identification data, system name, build timestamp, etc.

## Ubuntu Core 16/18 support
Support for Ubuntu Core 16/18 is no more supported by uc-image.
