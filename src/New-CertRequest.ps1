#Requires -Version 5.1
<#
.SYNOPSIS
    Generates a CSR using values from a config object passed by Invoke-CertTool.ps1.
#>
Param (
    [Parameter(Mandatory = $true)]
    [object]$Config,

    [switch]$PassThru
)

$ErrorActionPreference = "Stop"

if ($Config -is [string]) {
    if (!(Test-Path $Config)) {
        throw "Config file not found: $Config"
    }
    $Config = Get-Content $Config -Raw | ConvertFrom-Json
}

$certDir  = $Config.outputDir
$domain   = $Config.domain
$infPath  = "$certDir\$domain.inf"
$csrPath  = "$certDir\$domain.csr"

# Ensure output directory exists
if (!(Test-Path -Path $certDir)) {
    Write-Host "  Creating output directory: $certDir"
    New-Item -ItemType Directory -Path $certDir -Force | Out-Null
}

Write-Host ""
Write-Host "  Generating CSR for: $domain" -ForegroundColor Cyan

# Build .inf content
$inf = @"
[Version]
Signature= "`$Windows NT`$"

[NewRequest]
Subject = "CN=$domain, C=$($Config.country), ST=$($Config.state), L=$($Config.locality), O=$($Config.organization)"
KeySpec = 1
KeyUsage = 0xA0
KeyLength = 2048
Exportable = TRUE
MachineKeySet = TRUE
SMIME = False
PrivateKeyArchive = FALSE
UserProtected = FALSE
UseExistingKeySet = FALSE
ProviderName = "Microsoft RSA SChannel Cryptographic Provider"
ProviderType = 12
RequestType = PKCS10
FriendlyName = "SSL Certificate for $domain"

[EnhancedKeyUsageExtension]
OID=1.3.6.1.5.5.7.3.1
"@

$inf | Out-File -FilePath $infPath -Encoding ascii
Write-Host "  INF written to: $infPath"

try {
    Write-Host "  Running certreq..." -ForegroundColor DarkGray
    certreq -new $infPath $csrPath
    Write-Host ""
    Write-Host "  CSR generated at: $csrPath" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Contents:" -ForegroundColor Cyan
    Get-Content -Path $csrPath
    Write-Host ""
    Write-Host "  Private key is stored in the Windows Certificate Store." -ForegroundColor DarkGray

    if ($PassThru) {
        [pscustomobject]@{
            InfPath = $infPath
            CsrPath = $csrPath
        }
    }
} catch {
    Write-Error "  Failed to generate CSR: $_"
}
