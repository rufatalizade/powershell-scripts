[object]$vmnames = (($($env:out)  | convertfrom-json).virtualMachineObj.value).prop.vmname

$alignVmName = @()
foreach ($vm in $vmnames)
    {
        [int]$i = $vmnames.IndexOf($vm)
        $i =$i + 1
        $alignVmName+=$vm+$i
        Write-Output $i
    }


function DscCompileForCd  { 
param([string]$vmname)

Write-Output $vmname 
Start-Sleep -Seconds 10

[int]$try = '0'
[int]$retryCount = '6'

while ($try -ne $retryCount)
    {

    Write-Output "searching DSC node to assign configuration"
        Start-Sleep -Seconds 20
        $nodeId  = (Get-AzAutomationDscNode -AutomationAccountName "AutomationAccountName" -ResourceGroupName "ResourceGroupName" -Name $vmname).Id
        [int]$count = $try++
        Write-Output $try 
        if ($nodeId)
                {
                 $try = $retryCount
                }
}

if ($nodeId) 
    {

        $nodeId = (Get-AzAutomationDscNode -AutomationAccountName "AutomationAccountName" -ResourceGroupName "ResourceGroupName" -Name $vmname).Id
        $nodeParams = @{
            NodeConfigurationName = "prodDefaultv1.localhost"
            ResourceGroupName = 'ResourceGroupName'
            Id = $nodeId
            AutomationAccountName = 'AutomationAccountName'
            Force = $true
            }
                $node = Set-AzAutomationDscNode @nodeParams

    }
        else 
            {
            Write-Output "After $retryCount attempt, DSC couldn't found $vmname node, please take a manual action from Azure Portal"
            }
}

foreach ($vm in $alignVmName)
    {
    DscCompileForCd -vmname $vm
    }

