# Custom Ubuntu Core image builder
This is command line tool for building Ubuntu Core images. It does follow ubuntu-image syntax. In addition it supports build of images in format for various flash tools and SoCs.

## Supported flash tools, SoCs:
- NXP: uuu flash tool
- Qualcomm: fastboot, qdl, QFIL
- Mediatek: native flash tool, fastboot
- Ambarella: AmbaUSB

## Standard features:
- -h, --help:              show this help message and exit"
- --snap SNAP              Install an extra snap, the snap argument can include additional information about the track|risk channel/branch with the following syntax: <snap>=<track|channel/branch>
                            examples: --snap go=1.14|stable
                                      --snap avahi.snap
- --revisions              Specify a subuntu-core-image.revisions file referencing the exact revisions of the provided snaps which should be installed. seeds.manifest is auto generated as ubuntu-core-image.revisions.
- --preseed                Create pressed image. Tool has to run as root.
- --preseed-sign-key       Name of the key to use to sign preseed assertion.
- --validation             Control of the validation sets, choose 'ignore' or 'enforce'.
- --preseed-sysfs-overlay  Overlay of sysfs to be used when building presseded image.
                           (--sysfs-overlay) This is required when building images with specific hw interfaces.
- --auto-import-assertion    Auto import assertion file to be included in root of main writable partiton. This assertion is imported once system is fully seeded. Passed file does not need to have correct file name, it will be renamed.
- --build-raw              Build raw disk images, instead of sparse one.
- -O,--output-dir          Output directory.
- -w DIRECTORY, --workdir  Working directory.
- -d, --debug              Print debug
- -dd                      Print verbose debugs
- -v|--version             Pring version info
- --disk-info              File to be used as .disk/info on the image's rootfs. This file can contain useful information about the target image, like image identification data, system name, build timestamp etc.

## Ubuntu Core 16/18 support
Support for Ubuntu Core 16/18 is no more supported by uc-image.