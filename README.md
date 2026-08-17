# Cert Utility

A lightweight toolset for generating certificate signing requests (CSRs) on Windows. Choose whichever interface suits your workflow.

---

## Quick Start

### Option 1 — Script (direct)

Generate a CSR directly from the command line by passing a config file path.

```powershell
cd C:\Repos\cert-utility
.\src\New-CertRequest.ps1 -Config .\config\default.config.json
```

Edit `config\default.config.json` beforehand to set your domain, organisation, and output directory.

---

### Option 2 — TUI (interactive menu)

Launch the terminal UI to view, edit, and save config interactively before generating the CSR.

```powershell
cd C:\Repos\cert-utility
.\Invoke-CertTool.ps1
```

Optionally supply a custom config file:

```powershell
.\Invoke-CertTool.ps1 -ConfigPath .\config\my-custom.config.json
```

Menu options: **[1]** Generate CSR · **[2]** View config · **[3]** Edit config · **[4]** Save config · **[Q]** Quit

---

### Option 3 — Web GUI

Launch the browser-based CSR builder. It posts the certificate details to a local PowerShell host, which generates the CSR and returns it straight back to your browser as a download.

```powershell
cd path\to\cert-utility
.\Start-CertWebGui.ps1
```

This also writes the matching `.inf` file to `outputDir`, and the private key remains in the Windows Certificate Store.

---

## Config file format

```json
{
  "domain":       "example.com",
  "country":      "GB",
  "state":        "England",
  "locality":     "London",
  "organization": "Acme Ltd",
  "outputDir":    "C:\\Certificates"
}
```

The generated `.csr` and `.inf` files are written to `outputDir`. The private key is stored in the Windows Certificate Store.
