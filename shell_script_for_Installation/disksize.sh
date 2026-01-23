#!/bin/bash

set -e

DISK="/dev/nvme0n1"
PART_NUM="4"
PART="${DISK}p${PART_NUM}"
VG_NAME="RootVG"

# Logical Volumes
LV_VAR="/dev/${VG_NAME}/varVol"
LV_VARTMP="/dev/${VG_NAME}/varTmpVol"
LV_LOG="/dev/${VG_NAME}/logVol"

# Size allocation (CHANGE IF NEEDED)
VAR_SIZE="+5G"
VARTMP_SIZE="+5G"
LOG_SIZE="+10G"

echo "===== Step 1: Growing partition ${PART} ====="
growpart ${DISK} ${PART_NUM}

echo "===== Step 2: Resizing Physical Volume ====="
pvresize ${PART}

echo "===== Step 3: Volume Group Free Space ====="
vgdisplay ${VG_NAME} | grep -i "Free"

echo "===== Step 4: Extending Logical Volumes ====="
lvextend -L ${VAR_SIZE} ${LV_VAR}
lvextend -L ${VARTMP_SIZE} ${LV_VARTMP}
lvextend -L ${LOG_SIZE} ${LV_LOG}

echo "===== Step 5: Growing Filesystems ====="

grow_fs() {
  MOUNT_POINT=$1
  LV_PATH=$2

  FS_TYPE=$(df -Th | awk -v mp="$MOUNT_POINT" '$7==mp {print $2}')

  if [[ "$FS_TYPE" == "xfs" ]]; then
    echo "Growing XFS filesystem on $MOUNT_POINT"
    xfs_growfs $MOUNT_POINT
  elif [[ "$FS_TYPE" == "ext4" ]]; then
    echo "Growing EXT4 filesystem on $LV_PATH"
    resize2fs $LV_PATH
  else
    echo "Unsupported filesystem on $MOUNT_POINT"
    exit 1
  fi
}

grow_fs "/var" "$LV_VAR"
grow_fs "/var/tmp" "$LV_VARTMP"
grow_fs "/var/log" "$LV_LOG"

echo "===== Step 6: Final Verification ====="
lsblk
df -h

echo "✅ LVM extension completed successfully"
