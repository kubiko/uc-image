# shellcheck shell=bash
#
# A/B slot support of uc-image.
#
# A gadget with the system-slot-a role asks for an image with A/B slots, as
# defined by the Ubuntu Core mini layout: two system slots and two apps slots,
# each a raw partition holding a nested GPT with one partition per snap. 'snap
# prepare-image', from a snapd which knows these roles, writes all of it: the
# slot images, the boot environment and the seed. Nothing it wrote is changed
# here, this is packaging: the slot images go to the output directory under the
# names the flashing lists use, and the gadget structures snapd does not create
# on the device get their images.
#
# uc-image sources this file, and everything specific to A/B is in it. The main
# script calls these functions only for a gadget that has the slots:
#   ab_check_image, ab_create_images, ab_manifest, ab_disk_structure_image
# Switch A/B support off with '--no-ab-support' or UC_IMAGE_AB_SUPPORT=off, or
# leave this file out of the snap.

# check 'snap prepare-image' wrote what a gadget with the slots asks for, which
# only a snapd that knows the slot roles does
ab_check_image () {
  print_debug 3 "ab_check_image"
  local file
  case "${BUILDER_CONFIG["BOOTLOADER"]}" in
    (grub | u-boot) ;;
    (*)
      print_debug 0 "A/B slots are supported with grub and u-boot, not with ${BUILDER_CONFIG["BOOTLOADER"]}, bailing out"
      exit 1
      ;;
  esac
  if [ -n "${BUILDER_CONFIG["SNAPD_RECOVERY_MODE"]}" ]; then
    print_debug 0 "--set-to-factory-reset is not supported on an image with A/B slots, bailing out"
    exit 1
  fi
  for file in ab-slots.json ubuntu-system.img
  do
    if [ ! -e "${BUILDER_CONFIG["WORK_DIR"]}/${file}" ]; then
      print_debug 0 "'snap prepare-image' wrote no [${file}], it needs a snapd which knows the A/B slot roles of the gadget, bailing out"
      exit 1
    fi
  done
  if [ -n "$("${YQ}" eval '.volumes.[].structure.[] | select(.role == "system-boot-state") | .name' "${BUILDER_CONFIG["GADGET_YAML"]}")" ] \
     && [ ! -e "${BUILDER_CONFIG["WORK_DIR"]}/ubuntu-boot-state.img" ]; then
    print_debug 0 "'snap prepare-image' wrote no [ubuntu-boot-state.img] for the gadget's system-boot-state structure, bailing out"
    exit 1
  fi
}

# create what the main script does not for a gadget with the slots
# - the slot images are 'snap prepare-image's, as they are
# - ubuntu-boot holds the boot environment on grub, and comes from the content
#   'snap prepare-image' resolved for it, where the main script leaves it to the
#   install. On an A/B system it is not created on the device
# - ubuntu-save and ubuntu-data are set up on the device, on the first boot
ab_create_images () {
  print_debug 3 "ab_create_images"
  local name fs_type size content_dir
  name=$("${YQ}" eval '.volumes.[].structure.[] | select(.role == "system-boot") | .name' "${BUILDER_CONFIG["GADGET_YAML"]}")
  if [ -n "${name}" ]; then
    size=$(name=${name} "${YQ}" eval '.volumes.[].structure.[] | select(.name == strenv(name)) | .size' "${BUILDER_CONFIG["GADGET_YAML"]}")
    fs_type=$(name=${name} "${YQ}" eval '.volumes.[].structure.[] | select(.name == strenv(name)) | .filesystem' "${BUILDER_CONFIG["GADGET_YAML"]}")
    content_dir="$(resolve_partition_content_dir "${name}")"
    if [ -z "${content_dir}" ] || [ ! -d "${content_dir}" ]; then
      content_dir="${BUILDER_CONFIG["WORK_DIR"]}/partitions/${name}"
      mkdir -p "${content_dir}"
    fi
    create_disk_image \
      "${content_dir}" \
      "${BUILDER_CONFIG["WORK_DIR"]}/partitions/${name}" \
      "${fs_type}" \
      "${name}" \
      "$(normalise_size_to_kb "${size}")k"
  fi

  cp "${BUILDER_CONFIG["WORK_DIR"]}/ubuntu-system.img" "${BUILDER_CONFIG["OUTPUT_DIR"]}/ubuntu-system.img"
  if [ -e "${BUILDER_CONFIG["WORK_DIR"]}/ubuntu-apps.img" ]; then
    cp "${BUILDER_CONFIG["WORK_DIR"]}/ubuntu-apps.img" "${BUILDER_CONFIG["OUTPUT_DIR"]}/ubuntu-apps.img"
  else
    # no app snap is seeded, the flashing list still writes the file, which
    # clears the start of the slot
    print_debug 1 "\nNo application snap is seeded, leaving ubuntu-apps empty"
    truncate -s 1M "${BUILDER_CONFIG["OUTPUT_DIR"]}/ubuntu-apps.img"
  fi
}

# the seed's snaps are links to devices of the target, so the manifest has the
# checksums of the slot images, and ab-slots.json says which snaps they hold
ab_manifest () {
  print_debug 3 "ab_manifest"
  local image
  mkdir -p "${BUILDER_CONFIG["MANIFEST_DIR"]}"
  cp "${BUILDER_CONFIG["WORK_DIR"]}/ab-slots.json" "${BUILDER_CONFIG["MANIFEST_DIR"]}/ab-slots.json"
  echo -e "\n### A/B slots ###"
  cat "${BUILDER_CONFIG["WORK_DIR"]}/ab-slots.json"
  echo -e "\n### slot image checksums ###"
  for image in ubuntu-system.img ubuntu-apps.img
  do
    if [ -e "${BUILDER_CONFIG["OUTPUT_DIR"]}/${image}" ]; then
      sha256sum "${BUILDER_CONFIG["OUTPUT_DIR"]}/${image}" | awk -F" |/" '{print $1, $NF}'
    fi
  done
}

# print the image of a structure of a disk image, nothing for a structure which
# stays empty, and return 1 for one the main script handles
# - role of the structure
ab_disk_structure_image () {
  local role="${1}"
  local apps_slot="apps-slot-b"
  # the apps image goes to the slot the first boot takes it from: on u-boot from
  # b, into the encrypted a. There is no encryption with grub yet, and it is
  # used where it lies
  [ "${BUILDER_CONFIG["BOOTLOADER"]}" = "grub" ] && apps_slot="apps-slot-a"
  case "${role}" in
    (system-slot-a)
      echo "${BUILDER_CONFIG["WORK_DIR"]}/ubuntu-system.img"
      ;;
    (system-boot-state)
      echo "${BUILDER_CONFIG["WORK_DIR"]}/ubuntu-boot-state.img"
      ;;
    (apps-slot-a | apps-slot-b)
      if [ "${role}" = "${apps_slot}" ] && [ -e "${BUILDER_CONFIG["WORK_DIR"]}/ubuntu-apps.img" ]; then
        echo "${BUILDER_CONFIG["WORK_DIR"]}/ubuntu-apps.img"
      fi
      ;;
    (system-slot-b | system-save | system-data)
      ;;
    (*)
      return 1
      ;;
  esac
  return 0
}
