<#
.Synopsis
Runbook that will run on hybrid worker to facilitate the on-premise provisioning tasks that are part of the server provisioning process
.Description


#>
Param(
    [string]$all,
    [string]$vmname = "demovm1",
    [string]$description = "description",
    [string]$domainname = "domain.net"
)

Write-Output $all
Write-Output "=========="
[object]$allvalues = (($all | convertfrom-json).all.value)
Write-Output $allvalues
Write-Output "=========="
[object]$vmobjs = (($all | convertfrom-json).virtualMachineObj.value).prop
Write-Output $vmobjs
Write-Output "=========="
[object]$vmnames = (($all | convertfrom-json).virtualMachineObj.value).prop.vmname
Write-Output $vmnames
Write-Output "=========="



#########
$runasacc = Get-AutomationPSCredential 'PrivelegedAccountAssetName'

#$env:Computername
$domain = Get-addomain -server $domainname -credential $runasacc
$masterserver = $domain.InfrastructureMaster



$alignVmName = @()
foreach ($vm in $vmnames)
    {
        [int]$i = $vms.IndexOf($vm)
        $i =$i + 1
        $alignVmName+=$vm+$i
        Write-Output $i
    }

foreach ($vm in $alignVmName)
    {

    Write-Output "checking whether $VM name exist"

    if (get-adcomputer -filter {name -EQ $vm} -server $masterserver -credential $runasacc -ErrorAction SilentlyContinue)
        {
        Write-Output "CheckResponse:Conflict"
        Write-Output "$VM name is being used in AD"
        throw [object] "Name conflict!"
        }
            else {
                    Write-Output "CheckResponse:Success"
                 }
}


