# OnePlus OxygenOS/ColorOS OTA Flasher

Follow these steps to download, extract, and flash your OnePlus firmware using OTA files.

### Step 1: Download the Full OTA ZIP  
  1. Download the full OTA `.zip` file from our OTA Downloader: https://roms.danielspringer.at/index.php?view=ota 

### Step 2: Extract the OTA ZIP   
  1. Download otaripper: https://github.com/syedinsaf/otaripper  
  2. Drag and drop the downloaded .zip file onto the exe file.  
  3. The tool will extract all .IMG files from the OTA package.  

### Step 3: Prepare Files for Flashing  
  1. Move all extracted .IMG files into the folder: OTA_FILES_HERE

### Step 4: Start the Flashing Process  
  1. Run the flashing script by executing: Universal_Flasher.bat (Win) or Universal_flasher.sh (Mac/Linux)
  
  
## WARNING  
Oneplus 15,15R & Ace 6T "needs" to extract system_dlkm_oki from edl package
Oneplus Ace 6 "needs" to extract system_dlkm_oki & system_dlkm_gki from edl package

as long as you are not flashing from a custom rom you can do without them
