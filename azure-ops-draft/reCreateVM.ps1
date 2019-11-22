
#below cmdlets are used to re-create same virtual configurations with different attached VHD disks

$rgName = "global" 
$vmName = "vmname1"

$pvm.AvailabilitySetReference.Id
$pvm.NetworkProfile.NetworkInterfaces.id
$pvm.StorageProfile.DataDisks.name  #lun0
$pvm.DiagnosticsProfile.BootDiagnostics.StorageUri
$newVMConfig.StorageProfile.OsDisk.EncryptionSettings = $t.StorageProfile.OsDisk.EncryptionSettings


$vm = Get-AzVM -Name "vmname1" -ResourceGroupName $rgName


Remove-AzVM -Name "vmname1" -ResourceGroupName $rgName -Force


$avsId  = $vm.AvailabilitySetReference.Id
$nicId  = $vm.NetworkProfile.NetworkInterfaces.id
$vmSize = $vm.HardwareProfile.VmSize
$vmTags = $vm.Tags


$newVMConfig = new-azvmconfig -VMSize "Standard_D2S_V3"  -VMName $vmName  -Tags $vmTags

### Add the OS Information
#Set-AzVMOperatingSystem -VM $newVMConfig -Windows -ComputerName $vmName -Credential $cred -ProvisionVMAgent -EnableAutoUpdate 
#Set-AzVMSourceImage -VM $newVMConfig -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2016-Datacenter


$newVMConfig.DiagnosticsProfile = $vm.DiagnosticsProfile

Add-AzVMNetworkInterface -vm $newVMConfig -id $nicId


$osdisk = Get-AzDisk -ResourceGroupName $rgName -DiskName  "vmdisk-OS02"
Set-AzVMOSDisk -vm $newVMConfig -Name "vmname1-OS02" -CreateOption Attach -ManagedDiskId $osdisk.Id -Windows 

$datadisk = Get-AzDisk -ResourceGroupName $rgName -DiskName  "vmdisk-DATA01" | Set-AzVMDataDisk -Name $newVMConfig
Add-AzVMDataDisk -VM $newVMConfig -Name "vmname1-DATA01" -Lun '0' -CreateOption attach -DiskSizeInGB $datadisk.DiskSizeGB -ManagedDiskId $datadisk.id

 
$NewVM = $newVMConfig | New-AzVM -ResourceGroupName $rgName -Location $vm.Location


$newVMConfig.StorageProfile.OsDisk.EncryptionSettings = $pvm.StorageProfile.OsDisk.EncryptionSettings
