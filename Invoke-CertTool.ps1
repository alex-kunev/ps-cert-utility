#Requires -Version 5.1
<#
.SYNOPSIS
    Cert Utility - TUI entry point.
    Reads config/default.config.json (or a custom config) and drives certificate operations.
.EXAMPLE
    .\Invoke-CertTool.ps1
    .\Invoke-CertTool.ps1 -ConfigPath ".\config\bhf.config.json"
#>
Param (
    [string]$ConfigPath = "$PSScriptRoot\config\default.config.json"
)

$ErrorActionPreference = "Stop"

# ── Helpers ─────────────────────────────────────────────────────────────────

function Read-Config {
    param ([string]$Path)
    if (!(Test-Path $Path)) {
        Write-Warning "Config not found at '$Path'. Using built-in defaults."
        return @{
            domain       = "mail.google.com"
            country      = "US"
            state        = "California"
            locality     = "Mountain View"
            organization = "GOOGLE LLC"
            outputDir    = "C:\Certificates"
        }
    }
    return Get-Content $Path -Raw | ConvertFrom-Json
}

function Save-Config {
    param ($Config, [string]$Path)
    $Config | ConvertTo-Json -Depth 3 | Out-File -FilePath $Path -Encoding utf8
    Write-Host "  Config saved to $Path" -ForegroundColor Green
}

function Show-Config {
    param ($Config)
    Write-Host ""
    Write-Host "  Current config:" -ForegroundColor Cyan
    Write-Host "    Domain       : $($Config.domain)"
    Write-Host "    Country      : $($Config.country)"
    Write-Host "    State        : $($Config.state)"
    Write-Host "    Locality     : $($Config.locality)"
    Write-Host "    Organization : $($Config.organization)"
    Write-Host "    Output dir   : $($Config.outputDir)"
    Write-Host ""
}

function Edit-Config {
    param ($Config)
    Write-Host ""
    Write-Host "  Leave blank to keep the current value." -ForegroundColor DarkGray
    Write-Host ""

    $fields = [ordered]@{
        domain       = "Domain (e.g. uat.defibfinder.uk)"
        country      = "Country code (e.g. GB)"
        state        = "State / County"
        locality     = "City / Locality"
        organization = "Organization"
        outputDir    = "Output directory"
    }

    foreach ($key in $fields.Keys) {
        $prompt  = "  $($fields[$key]) [$($Config.$key)]"
        $entered = Read-Host $prompt
        if ($entered -ne "") { $Config.$key = $entered }
    }

    return $Config
}

# ── Main menu ────────────────────────────────────────────────────────────────

$config = Read-Config -Path $ConfigPath

while ($true) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor DarkCyan
    Write-Host "  Cert Utility"                          -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor DarkCyan
    Write-Host "  [1] Generate CSR"
    Write-Host "  [2] View config"
    Write-Host "  [3] Edit config"
    Write-Host "  [4] Save config"
    Write-Host "  [Q] Quit"
    Write-Host ""
    $choice = Read-Host "  Select"

    switch ($choice.Trim().ToUpper()) {
        "1" {
            if ([string]::IsNullOrWhiteSpace($config.domain)) {
                Write-Warning "Domain is empty. Edit the config first (option 3)."
                break
            }
            & "$PSScriptRoot\src\New-CertRequest.ps1" -Config $config
        }
        "2" { Show-Config -Config $config }
        "3" { $config = Edit-Config -Config $config }
        "4" { Save-Config -Config $config -Path $ConfigPath }
        "Q" { Write-Host "  Bye." -ForegroundColor DarkGray; exit 0 }
        default { Write-Host "  Invalid option." -ForegroundColor Yellow }
    }
}
