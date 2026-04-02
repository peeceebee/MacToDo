<#
.SYNOPSIS
    Verifies and creates Azure resources for MacTodo.

.DESCRIPTION
    Ensures the resource group, storage account, and blob container exist.
    Creates any missing resources. Outputs the connection details for .env.

.PARAMETER StorageAccountName
    Globally unique Azure Storage account name (3-24 chars, lowercase + numbers only).

.PARAMETER Location
    Azure region for resource creation. Default: eastus.

.EXAMPLE
    ./setup-azure.ps1 -StorageAccountName "mactodostorage123"
    ./setup-azure.ps1 -StorageAccountName "mactodostorage123" -Location "westus2"
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-z0-9]{3,24}$')]
    [string]$StorageAccountName,

    [string]$Location = "eastus"
)

$ErrorActionPreference = "Stop"

$ResourceGroup = "rg-mactodo"
$ContainerName = "mactodo"

# --- Pre-flight: verify Az CLI is installed and logged in ---

Write-Host "Checking Azure CLI..." -ForegroundColor Cyan
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Error "Azure CLI (az) is not installed. Install from https://learn.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
}

$account = az account show 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Not logged in. Running 'az login'..." -ForegroundColor Yellow
    az login
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Azure login failed."
        exit 1
    }
}

$sub = az account show --query "{name:name, id:id}" -o json | ConvertFrom-Json
Write-Host "Using subscription: $($sub.name) ($($sub.id))" -ForegroundColor Green

# --- Resource Group ---

Write-Host "`nChecking resource group '$ResourceGroup'..." -ForegroundColor Cyan
$rgExists = az group exists --name $ResourceGroup
if ($rgExists -eq "true") {
    Write-Host "  Resource group '$ResourceGroup' exists." -ForegroundColor Green
} else {
    Write-Host "  Creating resource group '$ResourceGroup' in '$Location'..." -ForegroundColor Yellow
    az group create --name $ResourceGroup --location $Location --output none
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to create resource group."
        exit 1
    }
    Write-Host "  Created." -ForegroundColor Green
}

# --- Storage Account ---

Write-Host "`nChecking storage account '$StorageAccountName'..." -ForegroundColor Cyan
$saShow = az storage account show --name $StorageAccountName --resource-group $ResourceGroup 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "  Storage account '$StorageAccountName' exists." -ForegroundColor Green
} else {
    # Check if the name is globally available
    $nameCheck = az storage account check-name --name $StorageAccountName --query "nameAvailable" -o tsv
    if ($nameCheck -ne "true") {
        Write-Error "Storage account name '$StorageAccountName' is not available. Choose a different name."
        exit 1
    }

    Write-Host "  Creating storage account '$StorageAccountName' (Standard_LRS, StorageV2)..." -ForegroundColor Yellow
    az storage account create `
        --name $StorageAccountName `
        --resource-group $ResourceGroup `
        --location $Location `
        --sku Standard_LRS `
        --kind StorageV2 `
        --min-tls-version TLS1_2 `
        --allow-blob-public-access false `
        --output none
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to create storage account."
        exit 1
    }
    Write-Host "  Created." -ForegroundColor Green
}

# --- Get Storage Account Key ---

Write-Host "`nRetrieving storage account key..." -ForegroundColor Cyan
$storageKey = az storage account keys list `
    --account-name $StorageAccountName `
    --resource-group $ResourceGroup `
    --query "[0].value" -o tsv
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrEmpty($storageKey)) {
    Write-Error "Failed to retrieve storage account key."
    exit 1
}
Write-Host "  Key retrieved." -ForegroundColor Green

# --- Blob Container ---

Write-Host "`nChecking blob container '$ContainerName'..." -ForegroundColor Cyan
$containerExists = az storage container exists `
    --name $ContainerName `
    --account-name $StorageAccountName `
    --account-key $storageKey `
    --query "exists" -o tsv
if ($containerExists -eq "true") {
    Write-Host "  Container '$ContainerName' exists." -ForegroundColor Green
} else {
    Write-Host "  Creating container '$ContainerName'..." -ForegroundColor Yellow
    az storage container create `
        --name $ContainerName `
        --account-name $StorageAccountName `
        --account-key $storageKey `
        --output none
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to create blob container."
        exit 1
    }
    Write-Host "  Created." -ForegroundColor Green
}

# --- Output ---

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " Azure resources ready!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Add these to your .env file or Xcode scheme environment:" -ForegroundColor White
Write-Host ""
Write-Host "  AZURE_STORAGE_ACCOUNT=$StorageAccountName"
Write-Host "  AZURE_STORAGE_KEY=$storageKey"
Write-Host "  AZURE_CONTAINER_NAME=$ContainerName"
Write-Host ""

# --- Optionally write .env file ---

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$envFile = Join-Path (Split-Path -Parent $scriptDir) ".env"

$writeEnv = Read-Host "Write these values to $envFile? (y/N)"
if ($writeEnv -eq "y" -or $writeEnv -eq "Y") {
    @"
AZURE_STORAGE_ACCOUNT=$StorageAccountName
AZURE_STORAGE_KEY=$storageKey
AZURE_CONTAINER_NAME=$ContainerName
"@ | Set-Content -Path $envFile -Encoding UTF8
    Write-Host "Written to $envFile" -ForegroundColor Green
}
