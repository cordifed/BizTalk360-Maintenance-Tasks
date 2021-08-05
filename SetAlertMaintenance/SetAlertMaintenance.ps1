[cmdletBinding()]
param(
    [Parameter(Mandatory=$true,HelpMessage="BizTalk360 EnvironmentId. See Settings -> API Documentation.")]
    [string]$BizTalk360EnvironmentId,

    [Parameter(Mandatory=$true,HelpMessage="Url of the server where BizTalk360 is installed, e.g. http://localhost.")]
    [string]$BizTalk360ServerUrl
)

$DateTime = Get-Date

$ResponseSet = Invoke-RestMethod -Uri "$BizTalk360ServerUrl/BizTalk360/Services.REST/AdminService.svc/GetBizTalk360Info" -Method Get -UseDefaultCredentials
$BizTalk360Version = $ResponseSet.bizTalk360Info.biztalk360Version

## In BizTalk360 10.0, breaking changes were introduced to the API
if ($BizTalk360Version -ge '10.0')
{
    $UniversalDateTime = $DateTime.ToUniversalTime()
    $Request = '{
      "context": {
          "callerReference": "AzureDevOps",
          "environmentSettings": {
              "id": "' + $BizTalk360EnvironmentId + '"
          }
      },
      "alertMaintenance": {
          "name": "BizTalk Deploy",
          "comment": "This maintenance is created from Azure DevOps, as part of an automated deployment.",
          "maintenanceStartTime": "' + $UniversalDateTime.ToString("yyyy-MM-ddTHH:mm:ss.000") + '",
          "isOneTimeSchedule": true,
          "summary": "BizTalk Deploy",
          "scheduleConfiguration": {
            "recurrenceStartDate": "' + $DateTime.ToString("yyyyMMdd") + '",
            "recurrenceEndDate": "' + $DateTime.AddHours(1).ToString("yyyyMMdd") + '",
            "recurrenceStartTime": "' + $DateTime.ToString("HHmmss") + '",
            "recurrenceEndTime": "' + $DateTime.AddHours(1).ToString("HHmmss") + '",
            "isImmediate": true
          }
      }
  }
    '
}
## Between BizTalk360 9.0 and 9.1 a breaking change was done in the API
elseif ($BizTalk360Version -ge '9.1')
{
    $DateTime = $DateTime.ToUniversalTime()
    $Request = '{
      "context": {
        "callerReference": "AzureDevOps",
        "environmentSettings": {
          "id": "' + $BizTalk360EnvironmentId + '"
        }
      },
      "alertMaintenance": {
        "comment": "BizTalk Deploy",
        "maintenanceStartTime": "' + $DateTime.ToString("yyyy-MM-ddTHH:mm:ss.000") + '",
        "isOneTimeSchedule" : true,
        "summary": "BizTalk Deploy",
        "scheduleConfiguration": {
            "recurrenceStartDate": "' + $DateTime.ToString("yyyyMMdd") + '",
            "recurrenceEndDate": "' + $DateTime.AddHours(1).ToString("yyyyMMdd") + '",
            "recurrenceStartTime": "' + $DateTime.ToString("HHmmss") + '",
            "recurrenceEndTime": "' + $DateTime.AddHours(1).ToString("HHmmss") + '",
            "isImmediate": true
        }
      }
    }'
}
else
{
    $DateTime = $DateTime.ToUniversalTime()
    $Request = '{
      "context": {
        "callerReference": "AzureDevOps",
        "environmentSettings": {
          "id": "' + $BizTalk360EnvironmentId + '"
        }
      },
      "alertMaintenance": {
        "comment": "BizTalk Deploy",
        "maintenanceStartTime": "' + $DateTime.ToString("yyyy-MM-ddTHH:mm:ss.000") + '",
        "maintenanceTimeUnit": 0,
        "maintenanceTimeLength": 60,
        "isActive": true,
        "expiryDateTime": ""
      }
    }'
}

Write-Host $Request
$ResponseSet = Invoke-RestMethod -Uri "$BizTalk360ServerUrl/biztalk360/Services.REST/AlertService.svc/SetAlertMaintenance" -Method Post -ContentType "application/json" -Body $Request -UseDefaultCredentials
$ResponseSet

If ($ResponseSet.success)
{
    $maintenanceId = $ResponseSet.alertMaintenance.maintenanceId
    Write-Host "BizTalk360 maintenance mode successfully enabled, maintenanceId = $maintenanceId"
    Write-Host "##vso[task.setvariable variable=MaintenanceId;isOutput=true]$maintenanceId"
}
