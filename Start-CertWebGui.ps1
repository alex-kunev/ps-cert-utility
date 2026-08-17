#Requires -Version 5.1
<#
.SYNOPSIS
    Hosts the web GUI locally and uses PowerShell to generate/download a CSR.
#>
Param (
    [int]$Port = 8765
)

$ErrorActionPreference = "Stop"

$webRoot   = Join-Path $PSScriptRoot "web"
$indexPath = Join-Path $webRoot "index.html"

if (!(Test-Path $indexPath)) {
    throw "Web UI not found at '$indexPath'."
}

function Write-JsonResponse {
    param (
        [Parameter(Mandatory = $true)]$Context,
        [Parameter(Mandatory = $true)][int]$StatusCode,
        [Parameter(Mandatory = $true)][string]$Message
    )

    $payload = @{ message = $Message } | ConvertTo-Json
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($payload)
    $Context.Response.StatusCode = $StatusCode
    $Context.Response.ContentType = "application/json; charset=utf-8"
    $Context.Response.ContentLength64 = $bytes.Length
    $Context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    $Context.Response.Close()
}

function Get-RequestBody {
    param ([Parameter(Mandatory = $true)]$Request)

    $reader = New-Object System.IO.StreamReader($Request.InputStream, $Request.ContentEncoding)
    try {
        $reader.ReadToEnd()
    } finally {
        $reader.Dispose()
    }
}

function Get-NormalizedConfig {
    param ([Parameter(Mandatory = $true)]$Payload)

    $domain = [string]$Payload.domain
    $organization = [string]$Payload.organization
    $country = if ([string]::IsNullOrWhiteSpace([string]$Payload.country)) { "US" } else { ([string]$Payload.country).Trim().ToUpper() }

    if ([string]::IsNullOrWhiteSpace($domain) -or [string]::IsNullOrWhiteSpace($organization)) {
        throw [System.ArgumentException]::new("Domain and Organization are required.")
    }

    if ($country -notmatch '^[A-Z]{2}$') {
        throw [System.ArgumentException]::new("Country must be a 2-letter code.")
    }

    [pscustomobject]@{
        domain       = $domain.Trim()
        country      = $country
        state        = if ([string]::IsNullOrWhiteSpace([string]$Payload.state)) { "California" } else { ([string]$Payload.state).Trim() }
        locality     = if ([string]::IsNullOrWhiteSpace([string]$Payload.locality)) { "Mountain View" } else { ([string]$Payload.locality).Trim() }
        organization = $organization.Trim()
        outputDir    = if ([string]::IsNullOrWhiteSpace([string]$Payload.outputDir)) { "C:\Certificates" } else { ([string]$Payload.outputDir).Trim() }
    }
}

$listener = [System.Net.HttpListener]::new()
$prefix = "http://localhost:$Port/"
$listener.Prefixes.Add($prefix)
$listener.Start()

$url = $prefix.TrimEnd('/')
Write-Host "  Web GUI available at: $url" -ForegroundColor Green
Write-Host "  Press Ctrl+C to stop the local server." -ForegroundColor DarkGray
Start-Process $url

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        try {
            switch ($request.Url.AbsolutePath) {
                "/" {
                    $html = Get-Content -Path $indexPath -Raw
                    $bytes = [System.Text.Encoding]::UTF8.GetBytes($html)
                    $response.StatusCode = 200
                    $response.ContentType = "text/html; charset=utf-8"
                    $response.ContentLength64 = $bytes.Length
                    $response.OutputStream.Write($bytes, 0, $bytes.Length)
                    $response.Close()
                }
                "/generate" {
                    if ($request.HttpMethod -ne "POST") {
                        Write-JsonResponse -Context $context -StatusCode 405 -Message "Method not allowed."
                        break
                    }

                    $origin = $request.Headers["Origin"]
                    $referer = $request.Headers["Referer"]

                    if (
                        (![string]::IsNullOrWhiteSpace($origin) -and $origin -ne $url) -or
                        (![string]::IsNullOrWhiteSpace($referer) -and !($referer.StartsWith("$url/") -or $referer -eq $url))
                    ) {
                        Write-JsonResponse -Context $context -StatusCode 403 -Message "Forbidden origin."
                        break
                    }

                    try {
                        $body = Get-RequestBody -Request $request
                        $payload = $body | ConvertFrom-Json
                        $config = Get-NormalizedConfig -Payload $payload
                    } catch {
                        Write-JsonResponse -Context $context -StatusCode 400 -Message $_.Exception.Message
                        break
                    }

                    try {
                        $result = & "$PSScriptRoot\src\New-CertRequest.ps1" -Config $config -PassThru
                        $csrBytes = [System.IO.File]::ReadAllBytes($result.CsrPath)
                        $fileName = [System.IO.Path]::GetFileName($result.CsrPath)
                    } catch {
                        Write-Warning "CSR generation failed: $($_.Exception.Message)"
                        Write-JsonResponse -Context $context -StatusCode 500 -Message "Failed to generate the CSR: $($_.Exception.Message)"
                        break
                    }

                    $response.StatusCode = 200
                    $response.ContentType = "application/pkcs10"
                    $response.AddHeader("Content-Disposition", "attachment; filename=`"$fileName`"")
                    $response.ContentLength64 = $csrBytes.Length
                    $response.OutputStream.Write($csrBytes, 0, $csrBytes.Length)
                    $response.Close()
                }
                default {
                    Write-JsonResponse -Context $context -StatusCode 404 -Message "Not found."
                }
            }
        } catch {
            Write-JsonResponse -Context $context -StatusCode 500 -Message "Unexpected server error."
        }
    }
} finally {
    if ($listener.IsListening) {
        $listener.Stop()
    }
    $listener.Close()
}
