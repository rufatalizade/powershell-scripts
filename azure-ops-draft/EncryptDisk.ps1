 $sequenceVersion = [Guid]::NewGuid();
 $KVRGname = 'global';
 $VMRGName = 'global';
 $vmName = ‘vm1’;
 $aadClientID = 'xxxxx';
 $aadClientSecret = "xxx";
 $KeyVaultName = 'emeakv1';
 $KeyVault = Get-AzKeyVault -VaultName $KeyVaultName -ResourceGroupName $KVRGname;
 $diskEncryptionKeyVaultUrl = $KeyVault.VaultUri;
 $KeyVaultResourceId = $KeyVault.ResourceId;

 Set-AzVMDiskEncryptionExtension -ResourceGroupName $VMRGname -VMName $vmName -AadClientID $aadClientID `
 -AadClientSecret $aadClientSecret -DiskEncryptionKeyVaultUrl $diskEncryptionKeyVaultUrl -DiskEncryptionKeyVaultId $KeyVaultResourceId -VolumeType All –SequenceVersion $sequenceVersion;



 
$ResourceBkp = Get-AzResource -ResourceType Microsoft.Compute/disks -ResourceGroupName "global"-ResourceName "vmname1-OS01"
$Resource = Get-AzResource -ResourceType Microsoft.Compute/disks -ResourceGroupName "global"-ResourceName "vmname1-OS01"
$Resource.Properties.encryptionSettingsCollection.enabled = 'false'
$Resource.Properties.encryptionSettingsCollection.encryptionSettings = $null
$Resource | Set-AzResource -Force