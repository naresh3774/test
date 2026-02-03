// ============================================================
// AKS Maintenance Configuration Module Parameters
// ============================================================
param maintenanceDurationHours int
param maintenanceStartDate string
param maintenanceStartTime string
param maintenanceUtcOffset string
param maintenanceScheduleType string // 'daily', 'weekly', 'absoluteMonthly', 'relativeMonthly'
param maintenanceDayOfWeek string
param maintenanceIntervalWeeks int
param notAllowedDates array = []
param notAllowedTime array = []
param timeInWeek array = []

module maintenanceConfig './modules/maintenanceConfiguration.bicep' = {
  name: 'maintenanceConfigModule'
  scope: rg
  params: {
    aksResourceId: aks.outputs.aksId
    maintenanceConfigName: 'default'
    maintenanceDurationHours: maintenanceDurationHours
    maintenanceStartDate: maintenanceStartDate
    maintenanceStartTime: maintenanceStartTime
    maintenanceUtcOffset: maintenanceUtcOffset
    maintenanceScheduleType: maintenanceScheduleType
    weeklyDayOfWeek: maintenanceDayOfWeek
    weeklyIntervalWeeks: maintenanceIntervalWeeks
    notAllowedDates: notAllowedDates
    notAllowedTime: notAllowedTime
    timeInWeek: timeInWeek
  }
}
