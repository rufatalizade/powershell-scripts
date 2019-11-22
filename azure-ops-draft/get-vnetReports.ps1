


$emea=  (Get-AzVM -ResourceGroupName "global")
$emea | select name,@{n="network";e={((Get-AzResource -ResourceId $_.NetworkProfile.NetworkInterfaces.id).Properties.ipConfigurations.properties.subnet.id -split "/")[-3]}}

