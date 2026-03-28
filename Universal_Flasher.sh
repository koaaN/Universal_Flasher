#!/usr/bin/env bash

set -euo pipefail

# Change to script directory
cd "$(dirname "$0")"

# Locate fastboot
FASTBOOT="Platform-Tools/fastboot"
if [[ ! -x "$FASTBOOT" ]]; then
  if command -v fastboot >/dev/null 2>&1; then
    FASTBOOT="$(command -v fastboot)"
  else
    echo "\"$FASTBOOT\" not found and no fastboot in \$PATH."
    read -rp "Press Enter to exit..." _
    exit 1
  fi
fi

echo "**********************************************************************"
echo
echo "              OnePlus - Universal Flasher"
echo
echo "**********************************************************************"
echo

echo "************************      START FLASH     ************************"

# Flash the fastboot images first
"$FASTBOOT" flash boot_a          OTA_FILES_HERE/boot.img
"$FASTBOOT" flash boot_b          OTA_FILES_HERE/boot.img
"$FASTBOOT" flash dtbo_a          OTA_FILES_HERE/dtbo.img
"$FASTBOOT" flash dtbo_b          OTA_FILES_HERE/dtbo.img
"$FASTBOOT" flash init_boot_a     OTA_FILES_HERE/init_boot.img
"$FASTBOOT" flash init_boot_b     OTA_FILES_HERE/init_boot.img
"$FASTBOOT" flash modem_a         OTA_FILES_HERE/modem.img
"$FASTBOOT" flash modem_b         OTA_FILES_HERE/modem.img
"$FASTBOOT" flash recovery_a      OTA_FILES_HERE/recovery.img
"$FASTBOOT" flash recovery_b      OTA_FILES_HERE/recovery.img
"$FASTBOOT" flash vbmeta_a        OTA_FILES_HERE/vbmeta.img
"$FASTBOOT" flash vbmeta_b        OTA_FILES_HERE/vbmeta.img
"$FASTBOOT" flash vbmeta_system_a OTA_FILES_HERE/vbmeta_system.img
"$FASTBOOT" flash vbmeta_system_b OTA_FILES_HERE/vbmeta_system.img
"$FASTBOOT" flash vbmeta_vendor_a OTA_FILES_HERE/vbmeta_vendor.img
"$FASTBOOT" flash vbmeta_vendor_b OTA_FILES_HERE/vbmeta_vendor.img
"$FASTBOOT" flash vendor_boot_a   OTA_FILES_HERE/vendor_boot.img
"$FASTBOOT" flash vendor_boot_b   OTA_FILES_HERE/vendor_boot.img

###############################################################################
# super.img handling
###############################################################################

if [[ -f super.img ]]; then
  "$FASTBOOT" flash super super.img
fi

###############################################################################
# Reboot to fastbootd
###############################################################################

echo "  *******************      REBOOTING TO FASTBOOTD     *******************"
"$FASTBOOT" reboot fastboot
echo "  #################################"
echo "  #     Hit English on Phone      #"
echo "  #################################"
read -rp "Once the phone is in fastbootd, press Enter to continue..." _

###############################################################################
# Flash remaining .img files in OTA_FILES_HERE (excluding the ones above)
###############################################################################

EXCLUDED_IMAGES=(
  boot.img
  dtbo.img
  init_boot.img
  modem.img
  recovery.img
  vbmeta.img
  vbmeta_system.img
  vbmeta_vendor.img
  vendor_boot.img
  my_bigball.img
  my_carrier.img
  my_company.img
  my_engineering.img
  my_heytap.img
  my_manifest.img
  my_preload.img
  my_product.img
  my_region.img
  my_stock.img
  odm.img
  product.img
  system.img
  system_dlkm.img
  system_dlkm_oki.img
  system_dlkm_gki.img
  system_ext.img
  vendor.img
  vendor_dlkm.img
)

should_skip() {
  local name=$1
  for ex in "${EXCLUDED_IMAGES[@]}"; do
    if [[ "$name" == "$ex" ]]; then
      return 0
    fi
  done
  return 1
}

# Loop through all .img files in OTA_FILES_HERE but skip excluded images
for img in OTA_FILES_HERE/*.img; do
  [[ -e "$img" ]] || continue
  basename_img="$(basename "$img")"
  if should_skip "$basename_img"; then
    continue
  fi
  part="${basename_img%.img}"
  echo "Flashing ${part}..."
  "$FASTBOOT" flash --slot=all "$part" "$img"
done

###############################################################################
# Logical partitions handling when super.img is NOT used
###############################################################################

PARTITIONS=(
  my_bigball
  my_carrier
  my_engineering
  my_heytap
  my_manifest
  my_product
  my_region
  my_stock
  odm
  product
  system
  system_dlkm
  system_dlkm_oki
  system_dlkm_gki
  system_ext
  vendor
  vendor_dlkm
  my_company
  my_preload
)

# Delete, create & flash logical partitions only if that partition image exists
if [[ ! -f super.img ]]; then
  for p in "${PARTITIONS[@]}"; do
    if [[ -f "OTA_FILES_HERE/${p}.img" ]]; then
      echo "Processing ${p}..."
      "$FASTBOOT" delete-logical-partition "${p}_a"
      "$FASTBOOT" delete-logical-partition "${p}_b"
      "$FASTBOOT" delete-logical-partition "${p}_a-cow"
      "$FASTBOOT" delete-logical-partition "${p}_b-cow"
      "$FASTBOOT" create-logical-partition "${p}_a" 1
      "$FASTBOOT" create-logical-partition "${p}_b" 1
      "$FASTBOOT" flash "${p}_a" "OTA_FILES_HERE/${p}.img"
    fi
  done
fi

###############################################################################
# Change active slot to a
###############################################################################

"$FASTBOOT" --set-active=a
"$FASTBOOT" reboot fastboot

###############################################################################
# Final messages / wipe decisions
###############################################################################

echo "********************** CHECK ABOVE FOR ERRORS **************************"
echo "************** IF ERRORS, DO NOT BOOT INTO SYSTEM **********************"

# If super.img was NOT flashed, ask wipe question and then exit
read -rp "Do you want to wipe data? (y/N): " ans
case "$ans" in
  [yY]*)
    echo "****************** FLASHING COMPLETE *****************"
    echo "Wipe data by tapping Format Data on the screen, enter the code, and press format data."
    echo "Phone will automatically reboot into Android after wipe is done."
    read -rp "Press Enter when you're done..." _
    exit 0
    ;;
  *)
    echo "*********************** NO NEED TO WIPE DATA ****************************"
    read -rp "Flashing complete. Press Enter to reboot the phone to Android..." _
    "$FASTBOOT" reboot
    exit 0
    ;;
esac
