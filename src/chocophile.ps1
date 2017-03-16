# Command Line Parameters
# -------------------------------------------------------------------------------

param(
[switch] $export,
[switch] $uninstall,
[switch] $y,
[string] $chocofileName
)

$TASK = $args[0];

# Constants
# -------------------------------------------------------------------------------

$DEV=$true;

$PACKAGES_PATH = $Env:ChocolateyInstall + "\lib";
$DEF_CHOCOFILE_PATH = "./default.Chocofile";



# Dev
# -------------------------------------------------------------------------------

if ($DEV) {
    Clear-Host;
}



# Globals
# -------------------------------------------------------------------------------

# Performance

$SW = [Diagnostics.Stopwatch]::StartNew();

# Chocofile

$chocofilePath = $DEF_CHOCOFILE_PATH;
if ($chocofileName) { $chocofilePath = $chocofileName+".Chocofile"}


# Helpers
# -------------------------------------------------------------------------------

function PostWork {
    $SW.Stop();
    Write-Host "Task completed in" $SW.Elapsed.Milliseconds "ms";
}

function PromptIn {
    <#
    .SYNOPSIS
    Prompts the user for input
    .DESCRIPTION
    Will skip prompt if -y flag is set.
    Returns $false by default.
    This means in an if-else, the default flow should be in the else.
    .EXAMPLE
    PromptIn "what you wanna do?"
    #>
    $in = $false;
    if (!$y) {
        $in = Read-Host -Prompt $args[0];
    }
    return $in;
}

function GetNuspecs {
    <#
    .SYNOPSIS
    Gets nuspec files for all isntalled Chocolately packages
    .DESCRIPTION
    Return ArrayList of XmlDocument
    .EXAMPLE
    GetNuspecs
    #>
    $localPackages = Get-ChildItem $PACKAGES_PATH -Directory;
    $nuspecs = New-Object System.Collections.ArrayList;
    foreach ($package in $localPackages) {
        $nuspecFile = $package.GetFiles($package.Name + ".nuspec");
        if ($nuspecFile) {
            [ xml ]$nuspec = Get-Content -Path $nuspecFile.FullName;
            $nuspecs.Add($nuspec) > $null;
        }
    }
    return $nuspecs;
}



# Resources
# -------------------------------------------------------------------------------

# ----------------------------------------------------------------------------- #
#                                     Tasks                                     #
# ----------------------------------------------------------------------------- #



# Export
# -------------------------------------------------------------------------------

function ChocoExport {    
    Write-Host "Exporting installed Chocolatey packages to" $chocofilePath;
    
    if (Test-Path $chocofilePath) {
        Write-Host $chocofilePath "already exists.";
        $in = PromptIn "Replace old one? [Y/*|n]";
        if ($in -eq "n") {
            Write-Host "Guarding current Chocofile and exiting.";
            return;
        } else {
            Remove-Item $chocofilePath -Force > $null;
            Write-Host "Overwriting" $chocofilePath".";
        }
    }
    New-Item $chocofilePath -ItemType File > $null;
    
    $all = New-Object 'System.Collections.Generic.HashSet[string]';
    $ignorables = New-Object 'System.Collections.Generic.HashSet[string]';
    
    $nuspecs = GetNuspecs;
    foreach ($nuspec in $nuspecs) {
        $all.Add($nuspec.package.metadata.id) > $null;
        foreach ($dep in $nuspec.package.metadata.dependencies.dependency.id) {
            $ignorables.Add($dep) > $null;
        }
    }
    $all.ExceptWith($ignorables);
    
    foreach ($package in $all) {
        $package | Out-File $chocofilePath -Append;
    }
}

if ($export) {
    ChocoExport
}

if ($uninstall) {
    if (Test-Path $chocofilePath) {
        $chocofile = Get-Content $chocofilePath;
        $packages = $chocofile -join ';';

        Write-Host "Uninstalling" ($chocofile -join ", ");
        choco uninstall $packages -y -x > $null;
    }
} else {
    if (Test-Path $chocofilePath) {
        $chocofile = Get-Content $chocofilePath;
        $packages = $chocofile -join ';';
        
        Write-Host "Installing" ($chocofile -join ", ");
        choco install $packages -y > $null;
    }
}








PostWork