



$b = $a | select name,@{l="ifHasIP";e={

if ((Get-AzNetworkInterface -ResourceId $_.NetworkProfile.NetworkInterfaces.id).IpConfigurations.publicIPAddress.id)
    {
     (Get-AzPublicIpAddress -Name (Split-Path -Leaf ((Get-AzNetworkInterface -ResourceId $_.NetworkProfile.NetworkInterfaces.id).IpConfigurations.publicIPAddress).id)).IpAddress

    }
    else {
        "notHasIp"
            }

}}

