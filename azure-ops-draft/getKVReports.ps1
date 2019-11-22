
  $allvms = Get-AzVM  -ResourceGroupName "rgName"
   
  $vmkeyVaultRep = @()   
  foreach ($vm in $allvms)
    {
     $kvurl = $vm.StorageProfile.OsDisk.EncryptionSettings.DiskEncryptionKey.SecretUrl
     if (!$kvurl)
            {
            $kvurl = "notConfigured"
            }
      $repTable = @{
                        "kvurl" = $kvurl
                        "rg"  = $vm.ResourceGroupName
                        "location" = $vm.location
                   }
                   $tbl  = New-Object -TypeName psobject  -Property $repTable
                   $vmkeyVaultRep += $tbl

    }






