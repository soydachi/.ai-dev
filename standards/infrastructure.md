# Estándares de infraestructura

## Terraform

### Versiones

- Terraform 1.6+
- Provider versions pinneadas
- Modules versionados

### Estructura de proyecto

```
infrastructure/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   ├── staging/
│   └── prod/
│
├── modules/                    # Módulos reutilizables
│   ├── networking/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── compute/
│   └── database/
│
└── shared/                     # Recursos compartidos (DNS, etc)
```

### Convenciones

```hcl
# ✅ Variables con descripción y tipo
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

# ✅ Locals para valores derivados
locals {
  name_prefix = "${var.project}-${var.environment}"
  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  })
}

# ✅ Recursos con naming consistente
resource "azurerm_resource_group" "main" {
  name     = "${local.name_prefix}-rg"
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_storage_account" "main" {
  name                     = "${replace(local.name_prefix, "-", "")}sa"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = var.environment == "prod" ? "GRS" : "LRS"
  
  tags = local.common_tags
  
  lifecycle {
    prevent_destroy = var.environment == "prod"
  }
}

# ✅ Outputs descriptivos
output "resource_group_id" {
  description = "ID of the main resource group"
  value       = azurerm_resource_group.main.id
}
```

### Módulos

```hcl
# modules/networking/variables.tf
variable "name" {
  description = "Name prefix for networking resources"
  type        = string
}

variable "address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnets" {
  description = "Map of subnet configurations"
  type = map(object({
    address_prefixes = list(string)
    service_endpoints = optional(list(string), [])
  }))
}

# modules/networking/main.tf
resource "azurerm_virtual_network" "main" {
  name                = "${var.name}-vnet"
  address_space       = var.address_space
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_subnet" "subnets" {
  for_each = var.subnets

  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = each.value.address_prefixes
  service_endpoints    = each.value.service_endpoints
}

# Uso del módulo
module "networking" {
  source = "../../modules/networking"
  
  name                = local.name_prefix
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  
  address_space = ["10.0.0.0/16"]
  subnets = {
    "app" = {
      address_prefixes  = ["10.0.1.0/24"]
      service_endpoints = ["Microsoft.Sql", "Microsoft.Storage"]
    }
    "data" = {
      address_prefixes = ["10.0.2.0/24"]
    }
  }
  
  tags = local.common_tags
}
```

### State management

```hcl
# backend.tf
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstateaccount"
    container_name       = "tfstate"
    key                  = "dev/terraform.tfstate"
  }
}
```

---

## Bash

### Shebang y opciones

```bash
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# -e: Exit on error
# -u: Error on undefined variables
# -o pipefail: Pipeline fails if any command fails
```

### Estructura de script

```bash
#!/usr/bin/env bash
set -euo pipefail

#######################################
# Script description
# 
# Usage: ./script.sh [options] <args>
#######################################

# ============================================
# Constants
# ============================================
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly LOG_FILE="/var/log/${SCRIPT_NAME%.sh}.log"

# ============================================
# Default values
# ============================================
VERBOSE=false
DRY_RUN=false
ENVIRONMENT="dev"

# ============================================
# Functions
# ============================================

log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') $*" | tee -a "$LOG_FILE"
}

log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $*" >&2 | tee -a "$LOG_FILE"
}

log_debug() {
    if [[ "$VERBOSE" == true ]]; then
        echo "[DEBUG] $(date '+%Y-%m-%d %H:%M:%S') $*" | tee -a "$LOG_FILE"
    fi
}

die() {
    log_error "$1"
    exit "${2:-1}"
}

usage() {
    cat <<EOF
Usage: $SCRIPT_NAME [options] <command>

Commands:
    deploy    Deploy the application
    rollback  Rollback to previous version

Options:
    -e, --environment   Environment (dev|staging|prod) [default: dev]
    -v, --verbose       Enable verbose output
    -n, --dry-run       Show what would be done
    -h, --help          Show this help message

Examples:
    $SCRIPT_NAME deploy -e prod
    $SCRIPT_NAME rollback -e staging -v
EOF
}

# ✅ Validación de dependencias
check_dependencies() {
    local deps=("jq" "curl" "az")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        die "Missing dependencies: ${missing[*]}"
    fi
}

# ✅ Cleanup on exit
cleanup() {
    local exit_code=$?
    log_debug "Cleaning up..."
    # Remove temp files, etc.
    exit $exit_code
}
trap cleanup EXIT

# ============================================
# Main
# ============================================

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -e|--environment)
                ENVIRONMENT="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -n|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            deploy|rollback)
                COMMAND="$1"
                shift
                ;;
            *)
                die "Unknown option: $1"
                ;;
        esac
    done
}

validate_args() {
    if [[ -z "${COMMAND:-}" ]]; then
        usage
        die "Command is required"
    fi
    
    if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
        die "Invalid environment: $ENVIRONMENT"
    fi
}

main() {
    parse_args "$@"
    validate_args
    check_dependencies
    
    log_info "Starting $COMMAND for $ENVIRONMENT"
    
    case "$COMMAND" in
        deploy)
            do_deploy
            ;;
        rollback)
            do_rollback
            ;;
    esac
    
    log_info "Completed successfully"
}

main "$@"
```

---

## PowerShell

### Estructura de script

```powershell
#Requires -Version 7.0
#Requires -Modules Az.Accounts, Az.Resources

<#
.SYNOPSIS
    Script description

.DESCRIPTION
    Detailed description

.PARAMETER Environment
    Target environment (dev, staging, prod)

.PARAMETER Verbose
    Enable verbose output

.EXAMPLE
    .\script.ps1 -Environment prod
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('dev', 'staging', 'prod')]
    [string]$Environment,
    
    [Parameter()]
    [switch]$DryRun
)

# ============================================
# Strict mode
# ============================================
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ============================================
# Constants
# ============================================
$Script:ScriptPath = $PSScriptRoot
$Script:LogFile = Join-Path $env:TEMP "script_$(Get-Date -Format 'yyyyMMdd').log"

# ============================================
# Functions
# ============================================

function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [ValidateSet('INFO', 'WARN', 'ERROR', 'DEBUG')]
        [string]$Level = 'INFO'
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logMessage = "[$Level] $timestamp $Message"
    
    switch ($Level) {
        'ERROR' { Write-Error $logMessage }
        'WARN'  { Write-Warning $logMessage }
        'DEBUG' { Write-Verbose $logMessage }
        default { Write-Host $logMessage }
    }
    
    Add-Content -Path $Script:LogFile -Value $logMessage
}

function Test-Prerequisites {
    [CmdletBinding()]
    param()
    
    Write-Log "Checking prerequisites..."
    
    # Check Azure connection
    $context = Get-AzContext -ErrorAction SilentlyContinue
    if (-not $context) {
        throw "Not connected to Azure. Run Connect-AzAccount first."
    }
    
    Write-Log "Connected to subscription: $($context.Subscription.Name)"
}

function Invoke-Deployment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Environment
    )
    
    if ($DryRun) {
        Write-Log "DRY RUN: Would deploy to $Environment"
        return
    }
    
    Write-Log "Deploying to $Environment..."
    # Deployment logic
}

# ============================================
# Main
# ============================================

try {
    Write-Log "Script started for environment: $Environment"
    
    Test-Prerequisites
    Invoke-Deployment -Environment $Environment
    
    Write-Log "Script completed successfully"
}
catch {
    Write-Log "Script failed: $_" -Level ERROR
    throw
}
finally {
    # Cleanup
}
```

---

## YAML

### Azure Pipelines

```yaml
# azure-pipelines.yml
trigger:
  branches:
    include:
      - main
      - develop
  paths:
    exclude:
      - docs/**
      - '*.md'

pr:
  branches:
    include:
      - main

pool:
  vmImage: 'ubuntu-latest'

variables:
  - group: common-variables
  - name: buildConfiguration
    value: 'Release'
  - name: dotnetVersion
    value: '8.0.x'

stages:
  - stage: Build
    displayName: 'Build & Test'
    jobs:
      - job: BuildJob
        displayName: 'Build'
        steps:
          - task: UseDotNet@2
            displayName: 'Setup .NET'
            inputs:
              version: $(dotnetVersion)

          - task: DotNetCoreCLI@2
            displayName: 'Restore'
            inputs:
              command: 'restore'
              projects: '**/*.csproj'

          - task: DotNetCoreCLI@2
            displayName: 'Build'
            inputs:
              command: 'build'
              projects: '**/*.csproj'
              arguments: '--configuration $(buildConfiguration) --no-restore'

          - task: DotNetCoreCLI@2
            displayName: 'Test'
            inputs:
              command: 'test'
              projects: '**/*Tests.csproj'
              arguments: '--configuration $(buildConfiguration) --no-build --collect:"XPlat Code Coverage"'

          - task: PublishCodeCoverageResults@1
            displayName: 'Publish coverage'
            inputs:
              codeCoverageTool: 'Cobertura'
              summaryFileLocation: '$(Agent.TempDirectory)/**/coverage.cobertura.xml'

  - stage: Deploy_Dev
    displayName: 'Deploy to Dev'
    dependsOn: Build
    condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/develop'))
    jobs:
      - deployment: DeployDev
        environment: 'development'
        strategy:
          runOnce:
            deploy:
              steps:
                - template: templates/deploy-steps.yml
                  parameters:
                    environment: 'dev'
```

### GitHub Actions

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  DOTNET_VERSION: '8.0.x'
  NODE_VERSION: '20.x'

jobs:
  build:
    name: Build & Test
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup .NET
        uses: actions/setup-dotnet@v4
        with:
          dotnet-version: ${{ env.DOTNET_VERSION }}

      - name: Cache NuGet packages
        uses: actions/cache@v4
        with:
          path: ~/.nuget/packages
          key: ${{ runner.os }}-nuget-${{ hashFiles('**/*.csproj') }}
          restore-keys: |
            ${{ runner.os }}-nuget-

      - name: Restore
        run: dotnet restore

      - name: Build
        run: dotnet build --configuration Release --no-restore

      - name: Test
        run: dotnet test --no-build --configuration Release --collect:"XPlat Code Coverage"

      - name: Upload coverage
        uses: codecov/codecov-action@v4
        with:
          files: '**/coverage.cobertura.xml'

  deploy:
    name: Deploy
    needs: build
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: production
    
    steps:
      - name: Deploy
        run: echo "Deploying..."
```

### Docker Compose

```yaml
# docker-compose.yml
version: '3.8'

services:
  api:
    build:
      context: .
      dockerfile: src/Api/Dockerfile
      args:
        - BUILD_CONFIGURATION=Release
    ports:
      - "8080:8080"
    environment:
      - ASPNETCORE_ENVIRONMENT=Development
      - ConnectionStrings__Default=${DB_CONNECTION_STRING}
    depends_on:
      db:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: ${DB_USER:-app}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: ${DB_NAME:-appdb}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER:-app}"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

## Checklist para el agente

### Terraform
- [ ] Variables con tipo y descripción
- [ ] Locals para valores derivados
- [ ] Naming consistente con prefijos
- [ ] Tags en todos los recursos
- [ ] Outputs descriptivos
- [ ] State remoto configurado

### Bash
- [ ] set -euo pipefail
- [ ] Funciones para logging
- [ ] Validación de argumentos
- [ ] Check de dependencias
- [ ] Cleanup con trap

### PowerShell
- [ ] Set-StrictMode
- [ ] CmdletBinding y parámetros tipados
- [ ] Try/Catch/Finally
- [ ] Write-Log estructurado
- [ ] Validación de prerequisites

### YAML
- [ ] Indentación consistente (2 espacios)
- [ ] Variables para valores reutilizables
- [ ] Conditions y dependencies claros
- [ ] Templates para pasos comunes
