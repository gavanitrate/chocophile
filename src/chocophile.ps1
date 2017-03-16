# Command Line Parameters
# -------------------------------------------------------------------------------

param(
$TASK,
[switch] $y,
[string] $chocofileName
)



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
    Gets nuspec files for all installed Chocolately packages
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






# ----------------------------------------------------------------------------- #
#                                     Tasks                                     #
# ----------------------------------------------------------------------------- #



# Export
# -------------------------------------------------------------------------------

function ExportTask {
    Write-Host "Exporting installed Chocolatey packages to" $chocofilePath".";
    
    if (Test-Path $chocofilePath) {
        Write-Host $chocofilePath "already exists.";
        $in = PromptIn "Replace old one?([Y]es/[n]o)";
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
    $ignorables.Add("chocolatey") > $null;
    
    $nuspecs = GetNuspecs;
    foreach ($nuspec in $nuspecs) {
        $all.Add($nuspec.package.metadata.id) > $null;
        foreach ($dep in $nuspec.package.metadata.dependencies.dependency.id) {
            $ignorables.Add($dep) > $null;
        }
    }
    $all.ExceptWith($ignorables);
    
    if ($all.Count -eq 0) {
        Write-Host "No Chocolatey packages are installed. Deleting" $chocofilePath".";
        Remove-Item $chocofilePath -Force > $null;
    } else {
        foreach ($package in $all) {
            $package | Out-File $chocofilePath -Append;
        }
    }
}

function UninstallTask {
    if (Test-Path $chocofilePath) {
        $chocofile = Get-Content $chocofilePath;
        $packages = $chocofile -join ';';
        
        Write-Host "Uninstalling" ($chocofile -join ", ");
        choco uninstall $packages -y -x > $null;
    } else {
        Write-Host $chocofilePath "does not exist."
    }
}

function InstallTask {
    if (Test-Path $chocofilePath) {
        $chocofile = Get-Content $chocofilePath;
        $packages = $chocofile -join ';';
        
        Write-Host "Installing" ($chocofile -join ", ");
        choco install $packages -y > $null;
    } else {
        Write-Host $chocofilePath "does not exist."
    }
}






# ----------------------------------------------------------------------------- #
#                                    Routing                                    #
# ----------------------------------------------------------------------------- #

switch ($TASK) {
    {$_ -in "i","install"} { InstallTask }
    {$_ -in "u","uninstall","remove"} { UninstallTask }
    {$_ -in "e","export"} { ExportTask }
    
    Default { Write-Host "Incorrect usage." }
}






PostWork