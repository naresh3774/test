# ArcGIS Notebook Server Automation - Single Node (No HA)

## Folder Structure

C:\ArcGIS-Automation\
├── Config\config.psd1           # Environment variables, storage, Key Vault, portal
├── DSC\NotebookServer.ps1       # DSC script for installation
├── Invoke-NotebookSetup.ps1     # Optional wrapper script
└── README.md                    # Instructions

## How to Run

1. Copy all folders and files to your VM (C:\ArcGIS-Automation)
2. Open PowerShell as Administrator
3. Run:

Set-ExecutionPolicy Bypass -Scope Process -Force
cd C:\ArcGIS-Automation
.\Invoke-NotebookSetup.ps1

## Pre-requisites

- Windows Server 2022
- System-assigned Managed Identity enabled
- Azure CLI installed and accessible
- Key Vault secrets:
  - Portal username/password
  - Notebook certificate password
- Azure Storage blobs:
  - Notebook Server installer
  - License file
  - PFX certificate
- Ports open:
  - 11443 (Notebook Server)
  - 443 (Portal)
- Docker runtime will be installed if missing

This setup is **ready to run** as a single-node Notebook Server without HA.
