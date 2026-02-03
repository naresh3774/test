// ============================================================
// AKS Maintenance Configuration Module
// ============================================================

param aksResourceId string
param maintenanceConfigName string
param maintenanceDurationHours int
param maintenanceStartDate string
param maintenanceStartTime string
param maintenanceUtcOffset string
param maintenanceScheduleType string // 'daily', 'weekly', 'absoluteMonthly', 'relativeMonthly'
param dailyIntervalDays int = 1
param weeklyDayOfWeek string = 'Sunday'
param weeklyIntervalWeeks int = 1
param absoluteMonthlyDayOfMonth int = 1
param absoluteMonthlyIntervalMonths int = 1
param relativeMonthlyDayOfWeek string = 'Sunday'
param relativeMonthlyWeekIndex string = 'Last'
param relativeMonthlyIntervalMonths int = 1
param notAllowedDates array = []
param notAllowedTime array = []
param timeInWeek array = []

resource aksMaintenanceConfig 'Microsoft.ContainerService/managedClusters/maintenanceConfigurations@2025-10-02-preview' = {
  name: '${aksResourceId}/default'
  properties: {
    maintenanceWindow: {
      durationHours: maintenanceDurationHours
      notAllowedDates: notAllowedDates
      schedule: {
        daily: maintenanceScheduleType == 'daily' ? {
          intervalDays: dailyIntervalDays
        } : null
        weekly: maintenanceScheduleType == 'weekly' ? {
          dayOfWeek: weeklyDayOfWeek
          intervalWeeks: weeklyIntervalWeeks
        } : null
        absoluteMonthly: maintenanceScheduleType == 'absoluteMonthly' ? {
          dayOfMonth: absoluteMonthlyDayOfMonth
          intervalMonths: absoluteMonthlyIntervalMonths
        } : null
        relativeMonthly: maintenanceScheduleType == 'relativeMonthly' ? {
          dayOfWeek: relativeMonthlyDayOfWeek
          weekIndex: relativeMonthlyWeekIndex
          intervalMonths: relativeMonthlyIntervalMonths
        } : null
      }
      startDate: maintenanceStartDate
      startTime: maintenanceStartTime
      utcOffset: maintenanceUtcOffset
    }
    notAllowedTime: notAllowedTime
    timeInWeek: timeInWeek
  }
}

output maintenanceConfigId string = aksMaintenanceConfig.id
output maintenanceConfigName string = aksMaintenanceConfig.name
