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
