# Check Path
# ----------------------------------------------------------------------------

$ENTRY_POINT = "chocophile.ps1";

$SRC_DIR = "./src"
$SRC_ENTRY = "$SRC_DIR/$ENTRY_POINT";

if (-Not (Test-Path $SRC_ENTRY)) {
    Write-Host "Could not find source entry point.";
    Write-Host "Make sure you are calling the script from the root folder of the project.";
    return;
}

$BUILD_DIR = "./build"
$BUILD_SRC_DIR = "./build/src"
$BUILD_SRC_ENTRY = "./build/src/$ENTRY_POINT"

# Download build tools (if not exists)
if (-Not (Test-Path $BUILD_DIR)) {
    & .\scripts\download-build-tools.ps1
}

# Delete source files in build folder (if exists)
if (Test-Path $BUILD_SRC_DIR) {
    Remove-Item $BUILD_SRC_DIR -Force -Recurse
}

Write-Host "Starting build.";

# Copy source code (to be compiled) into build directory
Copy-Item $SRC_DIR $BUILD_DIR -recurse

# Build command
."$BUILD_DIR\ps2exe.ps1" "$BUILD_SRC_ENTRY" "$("$BUILD_DIR/$ENTRY_POINT" -replace '.ps1','.exe')"