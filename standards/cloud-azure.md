# Estándares Cloud Azure

## Convenciones de naming

### Formato general

```
{resource-type}-{workload}-{environment}-{region}-{instance}
```

### Ejemplos por recurso

| Recurso | Formato | Ejemplo |
|---------|---------|---------|
| Resource Group | `rg-{workload}-{env}-{region}` | `rg-payments-prod-weu` |
| Virtual Network | `vnet-{workload}-{env}-{region}` | `vnet-core-prod-weu` |
| Subnet | `snet-{purpose}` | `snet-app`, `snet-data` |
| Storage Account | `st{workload}{env}{region}` | `stpaymentsprodweu` |
| Key Vault | `kv-{workload}-{env}` | `kv-payments-prod` |
| App Service | `app-{workload}-{env}` | `app-api-prod` |
| Function App | `func-{workload}-{env}` | `func-processor-prod` |
| AKS Cluster | `aks-{workload}-{env}` | `aks-platform-prod` |
| Container Registry | `cr{workload}{env}` | `crplatformprod` |
| SQL Server | `sql-{workload}-{env}` | `sql-payments-prod` |
| SQL Database | `sqldb-{name}` | `sqldb-orders` |
| Service Bus | `sb-{workload}-{env}` | `sb-messaging-prod` |
| Event Hub | `evh-{workload}-{env}` | `evh-events-prod` |
| Application Insights | `appi-{workload}-{env}` | `appi-api-prod` |
| Log Analytics | `log-{workload}-{env}` | `log-platform-prod` |

### Abreviaturas de región

| Región | Abreviatura |
|--------|-------------|
| West Europe | weu |
| North Europe | neu |
| East US | eus |
| West US | wus |

### Abreviaturas de ambiente

| Ambiente | Abreviatura |
|----------|-------------|
| Development | dev |
| Staging | stg |
| Production | prod |

## Tagging obligatorio

```hcl
locals {
  required_tags = {
    Environment  = var.environment           # dev, stg, prod
    Project      = var.project_name          # nombre del proyecto
    CostCenter   = var.cost_center           # centro de costos
    Owner        = var.owner_email           # email del responsable
    ManagedBy    = "terraform"               # terraform, manual, arm
    CreatedDate  = formatdate("YYYY-MM-DD", timestamp())
  }
}
```

## Organización de subscripciones

```
Management Group: Company
├── Management Group: Platform
│   ├── Subscription: Platform-Shared        # DNS, networking hub
│   └── Subscription: Platform-Management    # Monitoring, security
│
├── Management Group: Workloads
│   ├── Management Group: Production
│   │   ├── Subscription: Prod-Payments
│   │   └── Subscription: Prod-Orders
│   │
│   └── Management Group: Non-Production
│       ├── Subscription: Dev-Workloads
│       └── Subscription: Staging-Workloads
│
└── Management Group: Sandbox
    └── Subscription: Sandbox
```

## Networking

### Hub-Spoke topology

```
                    ┌─────────────────┐
                    │   Hub VNet      │
                    │  10.0.0.0/16    │
                    │                 │
                    │  - Firewall     │
                    │  - VPN Gateway  │
                    │  - Bastion      │
                    └────────┬────────┘
                             │
         ┌───────────────────┼───────────────────┐
         │                   │                   │
┌────────┴────────┐ ┌────────┴────────┐ ┌────────┴────────┐
│  Spoke: App     │ │  Spoke: Data    │ │  Spoke: AKS     │
│  10.1.0.0/16    │ │  10.2.0.0/16    │ │  10.3.0.0/16    │
│                 │ │                 │ │                 │
│  - App Subnet   │ │  - SQL Subnet   │ │  - System Pool  │
│  - Web Subnet   │ │  - Redis Subnet │ │  - User Pool    │
└─────────────────┘ └─────────────────┘ └─────────────────┘
```

### Subnet sizing

```hcl
# ✅ Plan para crecimiento
subnets = {
  "snet-app" = {
    address_prefixes  = ["10.1.1.0/24"]   # 251 hosts
    service_endpoints = ["Microsoft.Sql", "Microsoft.Storage"]
  }
  "snet-aks-system" = {
    address_prefixes = ["10.3.0.0/22"]    # 1019 hosts
    delegation       = "Microsoft.ContainerService/managedClusters"
  }
  "snet-aks-user" = {
    address_prefixes = ["10.3.4.0/22"]    # 1019 hosts
    delegation       = "Microsoft.ContainerService/managedClusters"
  }
  "snet-pep" = {
    address_prefixes                          = ["10.1.2.0/24"]
    private_endpoint_network_policies_enabled = true
  }
}
```

## Azure Kubernetes Service (AKS)

### Configuración base

```hcl
resource "azurerm_kubernetes_cluster" "main" {
  name                = "aks-${var.workload}-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "aks-${var.workload}-${var.environment}"
  kubernetes_version  = "1.29"
  
  # ✅ System node pool
  default_node_pool {
    name                = "system"
    vm_size             = "Standard_D4s_v5"
    node_count          = 3
    vnet_subnet_id      = azurerm_subnet.aks_system.id
    zones               = ["1", "2", "3"]
    os_disk_type        = "Ephemeral"
    
    node_labels = {
      "nodepool" = "system"
    }
    
    only_critical_addons_enabled = true
  }
  
  # ✅ Managed identity
  identity {
    type = "SystemAssigned"
  }
  
  # ✅ Network config
  network_profile {
    network_plugin     = "azure"
    network_policy     = "calico"
    load_balancer_sku  = "standard"
    outbound_type      = "userDefinedRouting"
  }
  
  # ✅ Security
  azure_active_directory_role_based_access_control {
    managed                = true
    azure_rbac_enabled     = true
    admin_group_object_ids = [var.aks_admin_group_id]
  }
  
  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  }
  
  tags = local.common_tags
}

# ✅ User node pool
resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = "Standard_D8s_v5"
  min_count             = 2
  max_count             = 10
  vnet_subnet_id        = azurerm_subnet.aks_user.id
  zones                 = ["1", "2", "3"]
  os_disk_type          = "Ephemeral"
  enable_auto_scaling   = true
  
  node_labels = {
    "nodepool" = "user"
  }
  
  node_taints = []
  
  tags = local.common_tags
}
```

### Workload Identity

```yaml
# Kubernetes ServiceAccount
apiVersion: v1
kind: ServiceAccount
metadata:
  name: workload-identity-sa
  namespace: app
  annotations:
    azure.workload.identity/client-id: ${CLIENT_ID}
---
# Pod con Workload Identity
apiVersion: v1
kind: Pod
metadata:
  name: app
  namespace: app
  labels:
    azure.workload.identity/use: "true"
spec:
  serviceAccountName: workload-identity-sa
  containers:
    - name: app
      image: myapp:latest
```

## App Service / Azure Functions

```hcl
resource "azurerm_service_plan" "main" {
  name                = "asp-${var.workload}-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Linux"
  sku_name            = var.environment == "prod" ? "P2v3" : "B1"
  
  tags = local.common_tags
}

resource "azurerm_linux_web_app" "api" {
  name                = "app-${var.workload}-api-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  service_plan_id     = azurerm_service_plan.main.id
  
  # ✅ Managed Identity
  identity {
    type = "SystemAssigned"
  }
  
  site_config {
    always_on                = var.environment == "prod"
    http2_enabled            = true
    minimum_tls_version      = "1.2"
    ftps_state               = "Disabled"
    vnet_route_all_enabled   = true
    
    application_stack {
      dotnet_version = "8.0"
    }
    
    health_check_path = "/health"
  }
  
  app_settings = {
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.main.connection_string
    "KeyVaultName"                          = azurerm_key_vault.main.name
  }
  
  # ✅ VNet Integration
  virtual_network_subnet_id = azurerm_subnet.app.id
  
  tags = local.common_tags
}
```

## Key Vault

```hcl
resource "azurerm_key_vault" "main" {
  name                       = "kv-${var.workload}-${var.environment}"
  location                   = var.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  
  # ✅ Security settings
  enabled_for_disk_encryption     = false
  enabled_for_deployment          = false
  enabled_for_template_deployment = false
  enable_rbac_authorization       = true
  purge_protection_enabled        = var.environment == "prod"
  soft_delete_retention_days      = 90
  
  # ✅ Network rules
  network_acls {
    bypass                     = "AzureServices"
    default_action             = "Deny"
    virtual_network_subnet_ids = [azurerm_subnet.app.id]
  }
  
  tags = local.common_tags
}

# ✅ RBAC en lugar de access policies
resource "azurerm_role_assignment" "app_secrets" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_web_app.api.identity[0].principal_id
}
```

## Monitoring

### Application Insights + Log Analytics

```hcl
resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${var.workload}-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = var.environment == "prod" ? 90 : 30
  
  tags = local.common_tags
}

resource "azurerm_application_insights" "main" {
  name                = "appi-${var.workload}-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"
  
  tags = local.common_tags
}
```

### Alertas básicas

```hcl
resource "azurerm_monitor_metric_alert" "high_error_rate" {
  name                = "alert-${var.workload}-high-errors"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_linux_web_app.api.id]
  description         = "High error rate detected"
  severity            = 1
  frequency           = "PT5M"
  window_size         = "PT15M"
  
  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "Http5xx"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 10
  }
  
  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
}
```

## Private Endpoints

```hcl
# ✅ Private endpoint para SQL
resource "azurerm_private_endpoint" "sql" {
  name                = "pep-${azurerm_mssql_server.main.name}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.pep.id
  
  private_service_connection {
    name                           = "psc-sql"
    private_connection_resource_id = azurerm_mssql_server.main.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }
  
  private_dns_zone_group {
    name                 = "dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.sql.id]
  }
  
  tags = local.common_tags
}

resource "azurerm_private_dns_zone" "sql" {
  name                = "privatelink.database.windows.net"
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql" {
  name                  = "link-sql"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.sql.name
  virtual_network_id    = azurerm_virtual_network.main.id
}
```

## Checklist para el agente

### General
- [ ] Naming convention aplicada
- [ ] Tags obligatorios en todos los recursos
- [ ] Recursos en región correcta
- [ ] Resource locks en producción

### Networking
- [ ] Hub-spoke configurado
- [ ] NSGs en todas las subnets
- [ ] Private endpoints para PaaS
- [ ] DNS privado configurado

### Security
- [ ] Managed Identity (no service principals)
- [ ] Key Vault con RBAC
- [ ] TLS 1.2 mínimo
- [ ] Public access deshabilitado donde aplique

### Monitoring
- [ ] Application Insights configurado
- [ ] Diagnostic settings habilitados
- [ ] Alertas críticas definidas
- [ ] Log retention apropiado
