













#####################

# You can write your azure powershell scripts inline here. 
# You can also pass predefined and custom variables to this script using arguments
$json = $env:ARMOUTPUTS | convertfrom-json

$json.VMName.value
$json.VMDescription.value

$params = @{"VMNAME"="$json.VMName.value";"Country"="$($env:COUNTRY)";"Description"="$($json.VMDescription.value)"}

Start-AzureRmAutomationRunbook `
-ResourceGroupName "ResourceGroupName" `
–AutomationAccountName "AutomationAccountName" `
–Name "ProvisionVM_HybridSteps " `
-RunOn "Managed" `
-Parameters $params `
-MaxWaitSeconds 1000 `
-Wait