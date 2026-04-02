#!/usr/bin/env bash
#
# setup-azure.sh — Verify and create Azure resources for MacTodo.
#
# Usage:
#   ./Scripts/setup-azure.sh <storage_account_name> [location]
#
# Examples:
#   ./Scripts/setup-azure.sh mactodostorage123
#   ./Scripts/setup-azure.sh mactodostorage123 westus2

set -euo pipefail

RESOURCE_GROUP="rg-mactodo"
CONTAINER_NAME="mactodo"

# --- Args ---

if [ $# -lt 1 ]; then
    echo "Usage: $0 <storage_account_name> [location]"
    echo "  storage_account_name: globally unique, 3-24 chars, lowercase + numbers only"
    echo "  location: Azure region (default: eastus)"
    exit 1
fi

STORAGE_ACCOUNT="$1"
LOCATION="${2:-eastus}"

# Validate storage account name
if ! echo "$STORAGE_ACCOUNT" | grep -qE '^[a-z0-9]{3,24}$'; then
    echo "Error: Storage account name must be 3-24 characters, lowercase letters and numbers only."
    exit 1
fi

# --- Colors ---

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

info()    { echo -e "${CYAN}$*${NC}"; }
success() { echo -e "${GREEN}  ✔ $*${NC}"; }
warn()    { echo -e "${YELLOW}  → $*${NC}"; }
fail()    { echo -e "${RED}  ✘ $*${NC}"; exit 1; }

# --- Pre-flight: verify az CLI is installed and logged in ---

info "Checking Azure CLI..."
if ! command -v az &>/dev/null; then
    fail "Azure CLI (az) is not installed. Install from https://learn.microsoft.com/en-us/cli/azure/install-azure-cli"
fi

if ! az account show &>/dev/null; then
    warn "Not logged in. Running 'az login'..."
    az login || fail "Azure login failed."
fi

SUB_NAME=$(az account show --query "name" -o tsv)
SUB_ID=$(az account show --query "id" -o tsv)
success "Using subscription: $SUB_NAME ($SUB_ID)"

# --- Resource Group ---

info "\nChecking resource group '$RESOURCE_GROUP'..."
if az group exists --name "$RESOURCE_GROUP" | grep -q "true"; then
    success "Resource group '$RESOURCE_GROUP' exists."
else
    warn "Creating resource group '$RESOURCE_GROUP' in '$LOCATION'..."
    az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --output none \
        || fail "Failed to create resource group."
    success "Created."
fi

# --- Storage Account ---

info "\nChecking storage account '$STORAGE_ACCOUNT'..."
if az storage account show --name "$STORAGE_ACCOUNT" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
    success "Storage account '$STORAGE_ACCOUNT' exists."
else
    # Check global name availability
    NAME_AVAILABLE=$(az storage account check-name --name "$STORAGE_ACCOUNT" --query "nameAvailable" -o tsv)
    if [ "$NAME_AVAILABLE" != "true" ]; then
        fail "Storage account name '$STORAGE_ACCOUNT' is not available. Choose a different name."
    fi

    warn "Creating storage account '$STORAGE_ACCOUNT' (Standard_LRS, StorageV2)..."
    az storage account create \
        --name "$STORAGE_ACCOUNT" \
        --resource-group "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --sku Standard_LRS \
        --kind StorageV2 \
        --min-tls-version TLS1_2 \
        --allow-blob-public-access false \
        --output none \
        || fail "Failed to create storage account."
    success "Created."
fi

# --- Get Storage Account Key ---

info "\nRetrieving storage account key..."
STORAGE_KEY=$(az storage account keys list \
    --account-name "$STORAGE_ACCOUNT" \
    --resource-group "$RESOURCE_GROUP" \
    --query "[0].value" -o tsv)
if [ -z "$STORAGE_KEY" ]; then
    fail "Failed to retrieve storage account key."
fi
success "Key retrieved."

# --- Blob Container ---

info "\nChecking blob container '$CONTAINER_NAME'..."
CONTAINER_EXISTS=$(az storage container exists \
    --name "$CONTAINER_NAME" \
    --account-name "$STORAGE_ACCOUNT" \
    --account-key "$STORAGE_KEY" \
    --query "exists" -o tsv)
if [ "$CONTAINER_EXISTS" = "true" ]; then
    success "Container '$CONTAINER_NAME' exists."
else
    warn "Creating container '$CONTAINER_NAME'..."
    az storage container create \
        --name "$CONTAINER_NAME" \
        --account-name "$STORAGE_ACCOUNT" \
        --account-key "$STORAGE_KEY" \
        --output none \
        || fail "Failed to create blob container."
    success "Created."
fi

# --- Output ---

echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${GREEN} Azure resources ready!${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""
echo "Add these to your .env file or Xcode scheme environment:"
echo ""
echo "  AZURE_STORAGE_ACCOUNT=$STORAGE_ACCOUNT"
echo "  AZURE_STORAGE_KEY=$STORAGE_KEY"
echo "  AZURE_CONTAINER_NAME=$CONTAINER_NAME"
echo ""

# --- Optionally write .env file ---

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$(dirname "$SCRIPT_DIR")/.env"

read -p "Write these values to $ENV_FILE? (y/N) " WRITE_ENV
if [ "$WRITE_ENV" = "y" ] || [ "$WRITE_ENV" = "Y" ]; then
    cat > "$ENV_FILE" << EOF
AZURE_STORAGE_ACCOUNT=$STORAGE_ACCOUNT
AZURE_STORAGE_KEY=$STORAGE_KEY
AZURE_CONTAINER_NAME=$CONTAINER_NAME
EOF
    success "Written to $ENV_FILE"
fi
