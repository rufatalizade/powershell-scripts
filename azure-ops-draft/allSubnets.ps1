$azvnet  = Get-AzVirtualNetwork

$arr = @()
foreach ($vnet in $azvnet)

    {

    Write-Output $vnet.subnets.addressprefix 
    Write-Output "---------"

        foreach  ($v in $vnet.subnets.addressprefix) {
                    $hs = @{
                            "location"    = $vnet.location
                            "prefix" = $v
                            }
                                $obj =  New-Object -TypeName PsObject -Property $hs 
                                $arr += $obj
                }


    rv hs

    }

 