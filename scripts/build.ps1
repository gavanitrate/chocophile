# Constants


$ENTRY_POINT = "./src/chocophile.ps1";

if (-Not (Test-Path $ENTRY_POINT)) {
    Write-Host "Could not find source entry point.";
    Write-Host "Make sure you are calling the script from the root folder of the project.";
    return;
}

Write-Host "start";