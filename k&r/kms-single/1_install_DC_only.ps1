#Administrator Powershell-Rechte
Set-ExecutionPolicy Unrestricted

#UserProfile, Namen und Rechnername auslesen
dir env: | sort name

Get-Content Env:computername
Get-Content Env:userprofile
Get-Content Env:username

#Variablen übergeben
$UserName = gc env:username
$ComputerName = gc env:computername
$UserProfile = $VMPath
$VMPath = "D:\Users\ATN_65\Hyper-V\Test\"
$VMBase = "E:\Base"
$SRAM = 2GB
$VMSIntern = "kms-intern"
$VHDSize = 185GB
$PhysicalSectorSize = "4096"


# Interner MV-Switch erstellen für KMS2-Testumgebung
$Netz = Get-NetAdapter -physical | where status -eq "up"
$TestSwitch = Get-VMSwitch -name $VMSIntern -ErrorAction SilentlyContinue; if ($TestSwitch.Count -eq 0){New-VMSwitch -Name $VMSIntern -SwitchType Internal}

#Festplatten Clone für DomainController erstellen
New-VHD -path D:\users\ATN_65\Hyper-V\Test\DC1\KMS-DC1_0.vhdx -ParentPath E:\base\WindowsServer2016_en_gui_tmp.vhdx -PhysicalSectorSizeBytes $PhysicalSectorSize

#Zusätzliche Festplatten Domain Controller erstellen
New-VHD -path D:\users\ATN_65\Hyper-V\Test\DC1\KMS-DC1_1.vhdx -Dynamic -SizeBytes $VHDSize -PhysicalSectorSizeBytes $PhysicalSectorSize
New-VHD -path D:\users\ATN_65\Hyper-V\Test\DC1\KMS-DC1_2.vhdx -Dynamic -SizeBytes $VHDSize -PhysicalSectorSizeBytes $PhysicalSectorSize
New-VHD -path D:\users\ATN_65\Hyper-V\Test\DC1\KMS-DC1_3.vhdx -Dynamic -SizeBytes $VHDSize -PhysicalSectorSizeBytes $PhysicalSectorSize
New-VHD -path D:\users\ATN_65\Hyper-V\Test\DC1\KMS-DC1_4.vhdx -Dynamic -SizeBytes $VHDSize -PhysicalSectorSizeBytes $PhysicalSectorSize

#Zusätzliche Festplatten SRV1 erstellen
New-VHD -path D:\users\ATN_65\Hyper-V\Test\SRV1\KMS-SRV1_1.vhdx -Dynamic -SizeBytes $VHDSize -PhysicalSectorSizeBytes $PhysicalSectorSize
New-VHD -path D:\users\ATN_65\Hyper-V\Test\SRV1\KMS-SRV1_2.vhdx -Dynamic -SizeBytes $VHDSize -PhysicalSectorSizeBytes $PhysicalSectorSize

#Neue virtuelle Maschine Domain Controller DC1 erstellen
New-VM -name KMS-DC1 -Generation 2 -VHDPath D:\users\ATN_65\Hyper-V\Test\DC1\KMS-DC1_0.vhdx -MemoryStartupBytes $SRAM -SwitchName $VMSIntern -Path D:\users\ATN_65\Hyper-V\Test\DC1\
Set-VMMemory -VMName KMS-DC1 -DynamicMemoryEnabled $false
Set-VMProcessor -VMName KMS-DC1 -count 2

#Zusätzliche Festplatten zur virtuellen Maschine DC1 hinzufügen
Add-VMHardDiskDrive -ControllerType SCSI -VMName KMS-DC1 -Path D:\users\ATN_65\Hyper-V\Test\DC1\KMS-DC1_1.vhdx
Add-VMHardDiskDrive -ControllerType SCSI -VMName KMS-DC1 -Path D:\users\ATN_65\Hyper-V\Test\DC1\KMS-DC1_2.vhdx
Add-VMHardDiskDrive -ControllerType SCSI -VMName KMS-DC1 -Path D:\users\ATN_65\Hyper-V\Test\DC1\KMS-DC1_3.vhdx
Add-VMHardDiskDrive -ControllerType SCSI -VMName KMS-DC1 -Path D:\users\ATN_65\Hyper-V\Test\DC1\KMS-DC1_4.vhdx
Add-VMDvdDrive -VMName KMS-DC1 -ControllerNumber 0 

#MV Server und Client starten
Start-VM KMS-DC1

