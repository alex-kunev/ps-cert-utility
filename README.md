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

Open the browser-based config builder to fill in certificate details and download a ready-to-use config file, then pass it to either option above.

```powershell
# Open in your default browser
Start-Process .\web\index.html
```

Or simply open `web\index.html` directly in any browser — no server required.

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
