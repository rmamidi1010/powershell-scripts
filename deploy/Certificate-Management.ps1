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

function Certificate-CopyToStore {
    param(
        $cert_thumbprint,
        $source_store_name,
        $target_store_name,
        $source_store_scope = "LocalMachine",
        $target_store_scope = "LocalMachine"
    )

    Write-Host("Opening CertStore : '$source_store_scope\$source_store_name'...")
    $source_store = New-Object -TypeName System.Security.Cryptography.X509Certificates.X509Store -ArgumentList $source_store_name, $source_store_scope
    $source_store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadOnly)

    $cert = $source_store.Certificates | Where {$_.thumbprint -eq $cert_thumbprint}
    if (-not ($cert -ne $null)) {
        Write-Host("Could not find a certificate with the thumbprint '$cert_thumbprint' in '$source_store_scope\$source_store_name'!") -ForegroundColor "red"
    }

    Write-Host("Opening target CertStore : '$target_store_scope\$target_store_name'...")
    $target_store = New-Object -TypeName System.Security.Cryptography.X509Certificates.X509Store -ArgumentList $target_store_name, $target_store_scope
    $target_store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
    $target_store.Add($cert)

    $source_store.Close()
    $target_store.Close()
}

function Certificate-Import {
    param(
        $cert_file_path,
        $passphrase
    )

    Write-Host("Importing certificate '$cert_file_path'...") -ForegroundColor "cyan"
    if (($cert_file_path -ne "") -and ($passphrase -ne "") ) {
        if ($cert_file_path.EndsWith(".cer")) {
            CERTUTIL -f -addstore "My" $cert_file_path
        }
        else {
            if ((Get-Module PKI) -eq $null) {
                CERTUTIL -f -p $passphrase -importpfx $cert_file_path
            }
            else {
                if (-not (Test-Path function:\Import-PfxCertificate)) { Import-Module PKI }
                $secure_pass = ConvertTo-SecureString $passphrase -AsPlainText -Force
                Import-PfxCertificate -FilePath $cert_file_path "Cert:\LocalMachine\My" -Password $secure_pass
            }
        }
    }
}


