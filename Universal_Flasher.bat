@echo off
title Universal Flasher
echo.**********************************************************************
echo.
echo.              Oneplus - Universal Flasher                      
echo.
echo.**********************************************************************
@echo off

cd %~dp0
set fastboot=Platform-Tools\fastboot.exe
if not exist "%fastboot%" echo "%fastboot%" not found. & pause & exit /B 1
echo.************************      START FLASH     ************************

:: Flash the fastboot images first
%fastboot% flash boot_a OTA_FILES_HERE\boot.img
%fastboot% flash boot_b OTA_FILES_HERE\boot.img
%fastboot% flash dtbo_a OTA_FILES_HERE\dtbo.img
%fastboot% flash dtbo_b OTA_FILES_HERE\dtbo.img
%fastboot% flash init_boot_a OTA_FILES_HERE\init_boot.img
%fastboot% flash init_boot_b OTA_FILES_HERE\init_boot.img
%fastboot% flash modem_a OTA_FILES_HERE\modem.img
%fastboot% flash modem_b OTA_FILES_HERE\modem.img
%fastboot% flash recovery_a OTA_FILES_HERE\recovery.img
%fastboot% flash recovery_b OTA_FILES_HERE\recovery.img
%fastboot% flash vbmeta_a OTA_FILES_HERE\vbmeta.img
%fastboot% flash vbmeta_b OTA_FILES_HERE\vbmeta.img
%fastboot% flash vbmeta_system_a OTA_FILES_HERE\vbmeta_system.img
%fastboot% flash vbmeta_system_b OTA_FILES_HERE\vbmeta_system.img
%fastboot% flash vbmeta_vendor_a OTA_FILES_HERE\vbmeta_vendor.img
%fastboot% flash vbmeta_vendor_b OTA_FILES_HERE\vbmeta_vendor.img
%fastboot% flash vendor_boot_a OTA_FILES_HERE\vendor_boot.img
%fastboot% flash vendor_boot_b OTA_FILES_HERE\vendor_boot.img

:: Check if super.img exists
if exist "super.img" (
    %fastboot% flash super super.img
)

:: Reboot to fastbootd
%fastboot% reboot fastboot
echo.  *******************      REBOOTING TO FASTBOOTD     *******************
ECHO  #################################
ECHO  #      Hit English on Phone     #
ECHO  #################################
pause

:: Excluded files list (these should not be flashed again)
set excluded_images=boot.img dtbo.img init_boot.img modem.img recovery.img vbmeta.img vbmeta_system.img vbmeta_vendor.img vendor_boot.img my_bigball.img my_carrier.img my_company.img my_engineering.img my_heytap.img my_manifest.img my_preload.img my_product.img my_region.img my_stock.img odm.img product.img system.img system_dlkm.img system_dlkm_oki.img system_dlkm_oki.img system_ext.img vendor.img vendor_dlkm.img   

:: Loop through all .img files in OTA_FILES_HERE but skip excluded images
for %%G in (OTA_FILES_HERE\*.img) do (
    echo %excluded_images% | findstr /i /c:"%%~nxG" >nul
    if errorlevel 1 (
        echo Flashing %%~nG...
        %fastboot% flash --slot=all "%%~nG" "%%G"
    )
)

:: Define partitions list outside the IF block
set "partitions=my_bigball my_carrier my_engineering my_heytap my_manifest my_product my_region my_stock odm product system system_dlkm system_dlkm_oki system_dlkm_gki system_ext vendor vendor_dlkm my_company my_preload"

:: Check if super.img exists, if not, only process partitions whose image exists
if not exist "super.img" (
    for %%P in (%partitions%) do (
        if exist "OOS_FILES_HERE\%%P.img" (
            echo Processing %%P...
            %fastboot% delete-logical-partition %%P_a
            %fastboot% delete-logical-partition %%P_b
            %fastboot% delete-logical-partition %%P_a-cow
            %fastboot% delete-logical-partition %%P_b-cow
            %fastboot% create-logical-partition %%P_a 1
            %fastboot% create-logical-partition %%P_b 1
            %fastboot% flash %%P_a "OTA_FILES_HERE\%%P.img"
        )
    )
)

:: Change slot to a and reboot
%fastboot% --set-active=a
%fastboot% reboot fastboot

echo.********************** CHECK ABOVE FOR ERRORS **************************
echo.************** IF ERRORS, DO NOT BOOT INTO SYSTEM **********************

:: Ask for wipe data
choice /C YN /M "Do you want to wipe data?:"

if errorlevel 2 (
    echo *********************** NO NEED TO WIPE DATA ****************************
    echo ***** Flashing complete. Hit any key to reboot the phone to Android *****
    pause
    %fastboot% reboot
    exit /B 0
)

if errorlevel 1 (
    echo ****************** FLASHING COMPLETE *****************
    echo Wipe data by tapping Format Data on the screen, enter the code, and press format data.
    echo Phone will automatically reboot into Android after wipe is done.
    pause
    exit /B 0
)

