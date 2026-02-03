// ============================================================
// 8. AKS Maintenance Configuration Parameters
// ============================================================
// Environment-specific maintenance windows (picked up from global_settings.environment)
// nonprd (dev/staging): Thursday 3:00 PM - 5:00 PM CT (15:00 - 17:00)
// prod: Tuesday 6:00 AM - 8:00 AM CT (06:00 - 08:00)

param maintenanceDurationHours = 2
param maintenanceStartDate = '2026-02-05' // The maintenance schedule will first start on this date, then repeat weekly
param maintenanceStartTime = global_settings.environment == 'prod' ? '06:00' : '15:00'
param maintenanceUtcOffset = '-06:00' // Central Time (CT)
param maintenanceScheduleType = 'weekly'
param maintenanceDayOfWeek = global_settings.environment == 'prod' ? 'Tuesday' : 'Thursday'
param maintenanceIntervalWeeks = 1
param notAllowedDates = []
param notAllowedTime = []
param timeInWeek = []





// AKS Cluster Configuration
param systemNodePoolName = 'systempool'
param systemNodeCount = 3
param systemNodeVmSize = 'Standard_D4s_v3'
param availabilityZones = ['1', '2', '3']
param networkPlugin = 'azure'
param networkPluginMode = 'overlay'
param loadBalancerSku = 'standard'
param outboundType = 'userDefinedRouting'

// ACR Configuration
param acrSku = 'Premium'
param acrAdminUserEnabled = false
param privateDnsZoneName = 'privatelink.azurecr.us'

// Azure Monitor and Grafana Integration
param enableAzureMonitorMetrics = true
param azureMonitorWorkspaceResourceId = '/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.Monitor/accounts/<workspace-name>'
param grafanaResourceId = '/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.Dashboard/grafana/<grafana-name>'
