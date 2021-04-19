#Setting local defaults
$script:scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
# Sourcing dependencies
if(-not(Test-Path function:\Grant-AClPermission)) { . $scriptPath\Computer-Management.ps1}

function Certificate-TrustLocal {
    param(
        $cert_thumbprint
    )
    Write-Host("Trusting certificate : '$cert_thumbprint'") -ForegroundColor "cyan"
    Certificate-CopyToStore $cert_thumbprint "My" "TrustedPeople"
}


function Certificate-GrantKeyAccess {
    param(
        $cert_thumbprint,
        $user
    )

    $rsaFile = (Get-Item "Cert:\LocalMachine\My\$cert_thumbprint").privateKey.cspKeyContainerInfo.UniqueKeyContainerName
    $keyPath = "C:\ProgramData\Microsoft\Crypto\RSA\MachineKeys"
    $fullPath = "$keyPath\$rsaFile"
    Write-Host("Granting '$user' read-access to cert '$cert_thumbprint' keys")
    Grant-ACLPermission -filePath $fullPath -user $user
}
