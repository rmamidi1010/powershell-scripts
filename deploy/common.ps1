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
