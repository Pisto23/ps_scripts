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
$VMSIntern = "kms-intern"
$VMSExtern = "Extern"
$VMNames = "KMS-CL1","KMS-DC1","KMS-SRV1","KMS-SRV2"
$VMCheckPoint = "KMS-CL1","KMS-DC1","KMS-SRV1"
$CRAM = 1GB
$SRAM = 2GB
$VHDSize = 185GB
$VHDBlockSize = 1MB
$PhysicalSectorSize = "4096"

# Interner MV-Switch erstellen für KMS2-Testumgebung
$Netz = Get-NetAdapter -physical | where status -eq "up"
$TestSwitch = Get-VMSwitch -name $VMSIntern -ErrorAction SilentlyContinue; if ($TestSwitch.Count -eq 0){New-VMSwitch -Name $VMSIntern -SwitchType Internal}

#Festplatten Clone für SRV1 erstellen
New-VHD -path D:\users\ATN_65\Hyper-V\Test\SRV1\KMS-SRV1_0.vhdx -ParentPath E:\base\WindowsServer2016_en_core_tmp.vhdx -PhysicalSectorSizeBytes $PhysicalSectorSize

#Zusätzliche Festplatten SRV1 erstellen
New-VHD -path D:\users\ATN_65\Hyper-V\Test\SRV1\KMS-SRV1_1.vhdx -Dynamic -SizeBytes $VHDSize -PhysicalSectorSizeBytes $PhysicalSectorSize
New-VHD -path D:\users\ATN_65\Hyper-V\Test\SRV1\KMS-SRV1_2.vhdx -Dynamic -SizeBytes $VHDSize -PhysicalSectorSizeBytes $PhysicalSectorSize

#Neue virtuelle Maschine Server1 SRV1 erstellen
New-VM -name KMS-SRV1 -Generation 2 -VHDPath D:\users\ATN_65\Hyper-V\Test\SRV1\KMS-SRV1_0.vhdx -MemoryStartupBytes $SRAM -SwitchName $VMSIntern -Path D:\users\ATN_65\Hyper-V\Test\SRV1\
Set-VMMemory -VMName KMS-SRV1 -DynamicMemoryEnabled $false
Set-VMProcessor -VMName KMS-SRV1 -count 2

#Zusätzliche Festplatten zur virtuellen Maschine SRV1 hinzufügen
Add-VMHardDiskDrive -ControllerType SCSI -VMName KMS-SRV1 -Path D:\users\ATN_65\Hyper-V\Test\SRV1\KMS-SRV1_1.vhdx
Add-VMHardDiskDrive -ControllerType SCSI -VMName KMS-SRV1 -Path D:\users\ATN_65\Hyper-V\Test\SRV1\KMS-SRV1_2.vhdx
Add-VMDvdDrive -VMName KMS-SRV1 -ControllerNumber 0 

#MV Server und Client starten
Start-VM KMS-SRV1

