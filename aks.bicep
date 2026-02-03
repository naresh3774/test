// Outputs
output aksId string = aks.id
output aksName string = aks.name
output acrId string = acr.id
output acrName string = acr.name


// Azure Monitor Parameters
param enableAzureMonitorMetrics bool
param azureMonitorWorkspaceResourceId string
param grafanaResourceId string


azureMonitorProfile: enableAzureMonitorMetrics ? {
      metrics: {
        enabled: true
        kubeStateMetrics: {
          metricAnnotationsAllowList: ''
          metricLabelsAllowlist: ''
        }
      }
    } : null
