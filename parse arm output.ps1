"$($env:out)"
$jsout = $($env:out)
#Write-Host "##vso[task.setvariable variable=jsout]$jsout"
#Write-Output "================="
$all = (($($env:out)  | convertfrom-json).all.value)
Write-Output $all
#Write-Output "=========="
#$jsall = $all  | ConvertTo-Json
#Write-Host "##vso[task.setvariable variable=jsall]$jsall"
#Write-Output "=========="
[object]$virtualMachineObjs = (($($env:out)  | convertfrom-json).virtualMachineObj.value).prop
Write-Output $virtualMachineObjs
#write-output "==========="
#$jsVmObjs = $virtualMachineObjs  | ConvertTo-Json
#Write-Host "##vso[task.setvariable variable=jsVmObjs]$jsVmObjs"
Write-Output "=========="
[object]$vmnames = (($($env:out)  | convertfrom-json).virtualMachineObj.value).prop.vmname
Write-Output $vmnames