if (-Not (Test-Path "./src/chocophile.ps1")) {
    Write-Host "Could not find source entry point.";
    Write-Host "Make sure you are calling the script from the root folder of the project.";
    return;
}

if (Test-Path "./build") {
    Remove-Item "./build" -Force -Recurse
}

& ./scripts/build.ps1