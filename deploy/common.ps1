$INTERNAL_BUILD = "\\fileshares01\Shared\Deliverables\Internal\Builds"
$EXTERNAL_RELEASE = "\\fileshare01\Shared\Deliverables\External\Releases"
$LOCAL_DROP = "$HOME\Build"

$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
if (-not (Test-Path function:\Install-Font)) { Import-Module -Name $scriptPath\ext\pswinglue.0.5.0\PSWinGlue.psm1 -DisableNameChecking }

Add-Type -AssemblyName System.IO.Compression.FileSystem

$global:drives = Get-PSDrive -PSProvider "FileSystem" | where {$_.Free -ne $null}
$global:stats = @{}
$global:notes = @()

function fail-error {
    param(
        [string] $message
    )
    throw $message
    Exit 1
}

function Unzip
{
    param(
        [string]$zipfile, 
        [string]$outpath,
        [bool]$overwrite = $true
    )
    $src = Resolve-Path $zipfile
    $trg = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($outpath)

    if ($PSVERSIONTABLE.PSVersion.Major -lt 5) { 
        Add-Type -AssemblyName System.IO.Compression.FileSystem 
        # Since PS4.0 does not support overwrite during unzipping, the calling code need to manually taking care of it first
        # This is required for most of our 2008 R2 lab servers
        [System.IO.Compression.ZipFile]::ExtractToDirectory($src, $trg, $overwrite)
    } 
    else { 
        # 2016 Srv all have PS v5.0 installed by default, so overwrite switch is always on
        Expand-Archive -Path "$src" -DestinationPath "$trg" -Force 
    } 
}
