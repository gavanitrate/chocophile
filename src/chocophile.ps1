# Command Line Parameters
# -------------------------------------------------------------------------------

param(
$TASK,
$PACKAGES,
[switch] $y,
[string] $chocofileName
)



# Constants
# -------------------------------------------------------------------------------

$DEV=$true;

$PACKAGES_PATH = $Env:ChocolateyInstall + "\lib";
$DEF_CHOCOFILE_PATH = "default.Chocofile";



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
    if($PACKAGES) {
        Write-Host "This command installs the Chocolatey environment you have specified."
        Write-Host "If you are trying to add a Chocolatey package to a .Chocofile, you may be looking for the 'add' command."
        Write-Host "e.g. chocophile add sumatrapdf"
        return;
    }
    
    if (Test-Path $chocofilePath) {
        $chocofile = Get-Content $chocofilePath;
        $packages = $chocofile -join ';';
        
        Write-Host "Installing" ($chocofile -join ", ");
        choco install $packages -y > $null;
    } else {
        Write-Host $chocofilePath "does not exist."
    }
}

function AddTask {
    if(!$PACKAGES) {
        Write-Host "Please specify a package to add."
        return;
    }
    
    $packageSet = New-Object 'System.Collections.Generic.HashSet[string]';
    if (Test-Path $chocofilePath) {
        $chocofile = Get-Content $chocofilePath;
        
        foreach ($p in $chocofile) {
            $packageSet.Add($p) > $null;
        }
    }
    
    $ps = $PACKAGES -split ",";
    foreach ($p in $ps) {
        $packageSet.Add($p) > $null;
    }
    
    $packageSet | Out-File $chocofilePath;

    $packageStr = "package";
    if ($ps.Count -gt 1) {
        $packageStr+="s";
    }
    
    Write-Host "Added" $ps.Count $packageStr "to" $chocofilePath;
}

function RemoveTask {
    if(!$PACKAGES) {
        Write-Host "Please specify a package to remove."
        return;
    }
    
    $chocofileExists = Test-Path $chocofilePath;
    if(!$chocofileExists) {
        Write-Host $chocofilePath "does not exist"
        return;
    }
    
    $packageSet = New-Object 'System.Collections.Generic.HashSet[string]';
    $chocofile = Get-Content $chocofilePath;
    foreach ($p in $chocofile) {
        $packageSet.Add($p) > $null;
    }

    $ps = $PACKAGES -split ",";
    foreach ($p in $ps) {
        $packageSet.Remove($p) > $null;
    }
    
    $packageSet | Out-File $chocofilePath;
    
    $packageStr = "package";
    if ($ps.Count -gt 1) {
        $packageStr+="s";
    }

    Write-Host "Removed" $ps.Count $packageStr "from" $chocofilePath;
}






# ----------------------------------------------------------------------------- #
#                                    Routing                                    #
# ----------------------------------------------------------------------------- #

switch ($TASK) {
    {$_ -in "a","add"} { AddTask }
    {$_ -in "r","remove"} { RemoveTask }
    
    {$_ -in "i","install"} { InstallTask }
    {$_ -in "u","uninstall"} { UninstallTask }
    {$_ -in "e","export"} { ExportTask }
    
    Default { Write-Host "Incorrect usage." }
}






PostWork