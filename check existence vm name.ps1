$all = ($($env:out)  | convertfrom-json)
$params = @{
            "all" = "$($env:out)" ;
            "vmname" = "vmname1";
            "description" = "description2";
            "domainname" = "domain.net"
}

Start-AzureRmAutomationRunbook -ResourceGroupName "ResourceGroupName" `
–AutomationAccountName "AutomationAccountName" `
–Name "HybridWorkes" `
-RunOn "Managed" `
-Parameters $params `
-MaxWaitSeconds 1000 `
-Wait -OutVariable runbookout

if ((($runbookout | where {$_ -match "CheckResponse"}) -split ":")[1] -eq 'Conflict')
    {
        throw [object] "VM name conflict!"
    }
        elseif  ((($runbookout | where {$_ -match "CheckResponse"}) -split ":")[1] -eq 'Success')
            {
            Write-Output "VM name check in AD status: Success"
            }
               else {
                        throw [object] "VM name object couldn't found response patternt!"
                    }
