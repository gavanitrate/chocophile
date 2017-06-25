# Check Path
# ----------------------------------------------------------------------------

$ENTRY_POINT = "./src/chocophile.ps1";

if (-Not (Test-Path $ENTRY_POINT)) {
    Write-Host "Could not find source entry point.";
    Write-Host "Make sure you are calling the script from the root folder of the project.";
    return;
}

# Download
# ----------------------------------------------------------------------------

$PS2EXE_URL = "https://gallery.technet.microsoft.com/scriptcenter/PS2EXE-GUI-Convert-e7cb69d5/file/172772/2/PS2EXE-GUI.zip";

$BUILD_DIR = "./build";
$PS2EXE_OUTPUT = "$BUILD_DIR/ps2exe.zip";

if (-Not (Test-Path $BUILD_DIR)) {
    New-Item -ItemType Directory -Force -Path $BUILD_DIR | Out-Null;
    Invoke-WebRequest -Uri $PS2EXE_URL -OutFile $PS2EXE_OUTPUT;
    Expand-Archive $PS2EXE_OUTPUT -DestinationPath $BUILD_DIR;
}

Write-Host "Downloaded build tools.";