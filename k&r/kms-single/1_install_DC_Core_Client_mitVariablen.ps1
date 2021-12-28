#   ###########################################################   #
###########                                            ############
#   #####   Erstellen von: Net-Adapter (Intern & Extern)  #####   #
#######             DomainController (KMS-DC01)             #######
#   #                 CoreServer (KMS-SRV01)                  #   #
#######            Endian Firewall (KMS-Firewall)           #######
#   #####              Win10 Client (KMS-CL01)            #####   #
############                                           ############
#   ###########################################################   #



#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        #Administrator Powershell-Rechte
            Set-ExecutionPolicy Unrestricted

        #UserProfile, Namen und Rechnername auslesen
            dir env: | sort name
            Get-Content Env:computername
            Get-Content Env:userprofile
            Get-Content Env:username

# VARIABLEN ÜBERGEBEN-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            $UserName = gc env:username
            $ComputerName = gc env:computername
            $UserProfile = $VMPath
            $VMPath = "D:\Users\ATN_65\Hyper-V\KMS"
            $VMBase = "E:\Base"
        #Netadapter
            $VMSIntern = "kms-intern"
            $VMSExtern = "Extern"
        #Maschinen
            $nameDC = "KMS-DC1"
            $nameCore = "KMS-SRV1"
            $nameFW = "KMS-Firewall"
            $nameClient = "KMS-CL1"
            $CRAM = 1GB
            $SRAM = 2GB
            $DRAM = 4GB
            $VHDSize = 185GB
            $VHDBlockSize = 1MB
            $PhysicalSectorSize = "4096"
        #Pfade Parents
            $ParentDCpfad = "E:\base\WindowsServer2016_en_gui_tmp.vhdx"
            $ParentCorepfad = "E:\base\WindowsServer2016_en_core_tmp.vhdx"
            $ParentFIREWALLpfad = "E:\base\Endian_FW_tmp.vhdx"
            $ParentCLIENTpfad = "E:\base\Windows10_en_office_tmp.vhdx"
        #Pfade VMs        
            $VMpfadDC = "D:\users\ATN_65\Hyper-V\KMS\KMS-DC1\"
            $VMpfadCore = "D:\users\ATN_65\Hyper-V\KMS\KMS-SRV1"
            $VMpfadFirewall =  "D:\users\ATN_65\Hyper-V\KMS\KMS-Firewall\"
            $VMpfadClient =  "D:\users\ATN_65\Hyper-V\KMS\KMS-CL1\"
        #CP´s
            $VMCheckPoint = "KMS-CL1","KMS-DC1","KMS-SRV1"



# HYPER-V Netadapter erstellen, Extern und Intern--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    
            $Netz = Get-NetAdapter -physical | where status -eq "up"
            $TestSwitch = Get-VMSwitch -name $VMSIntern -ErrorAction SilentlyContinue; if ($TestSwitch.Count -eq 0){New-VMSwitch -Name $VMSIntern -SwitchType Internal}
            $TestSwitchEx = Get-VMSwitch -name $VMSExtern -ErrorAction SilentlyContinue; if ($TestSwitchEx.Count -eq 0){New-VMSwitch -Name $VMSExtern -NetAdapterName $Netz.Name} 
    


# DOMAIN CONTROLLER EINRICHTEN------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

        #Festplatten Clone für Domain Controller erstellen
            New-VHD -path $VMpfadDC\KMS-DC1_0.vhdx -ParentPath $ParentDCpfad -PhysicalSectorSizeBytes $PhysicalSectorSize

        #Zusätzliche Festplatten Domain Controller erstellen
            New-VHD -path $VMpfadDC\KMS-DC1_1.vhdx -Dynamic -SizeBytes $VHDSize -PhysicalSectorSizeBytes $PhysicalSectorSize
            New-VHD -path $VMpfadDC\KMS-DC1_2.vhdx -Dynamic -SizeBytes $VHDSize -PhysicalSectorSizeBytes $PhysicalSectorSize
            New-VHD -path $VMpfadDC\KMS-DC1_3.vhdx -Dynamic -SizeBytes $VHDSize -PhysicalSectorSizeBytes $PhysicalSectorSize
            New-VHD -path $VMpfadDC\KMS-DC1_4.vhdx -Dynamic -SizeBytes $VHDSize -PhysicalSectorSizeBytes $PhysicalSectorSize

        #Neue virtuelle Maschine Domain Controller erstellen
            New-VM -name $nameDC -Generation 2 -VHDPath $VMpfadDC\KMS-DC1_0.vhdx -MemoryStartupBytes $DRAM -SwitchName $VMSIntern -Path $VMpfadDC
            Set-VMMemory -VMName $nameDC -DynamicMemoryEnabled $false
            Set-VMProcessor -VMName $nameDC -count 4

    
        #Zusätzliche Festplatten zur virtuellen Maschine DC1 hinzufügen
            Add-VMHardDiskDrive -ControllerType SCSI -VMName $nameDC -Path $VMpfadDC\KMS-DC1_1.vhdx
            Add-VMHardDiskDrive -ControllerType SCSI -VMName $nameDC -Path $VMpfadDC\KMS-DC1_2.vhdx
            Add-VMHardDiskDrive -ControllerType SCSI -VMName $nameDC -Path $VMpfadDC\KMS-DC1_3.vhdx
            Add-VMHardDiskDrive -ControllerType SCSI -VMName $nameDC -Path $VMpfadDC\KMS-DC1_4.vhdx

        #SCSI Controller und DVD-Laufwerke
            Add-VMScsiController -VMName $nameDC
            Add-VMDvdDrive -VMName $nameDC -ControllerNumber 1



# CORE EINRICHTEN------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

        #Festplatten Clone für CoreServer erstellen
            New-VHD -path $VMpfadCore\KMS-SRV1_0.vhdx -ParentPath $ParentCorepfad -PhysicalSectorSizeBytes $PhysicalSectorSize

        #Zusätzliche Festplatten CoreServer erstellen
            New-VHD -path $VMpfadCore\KMS-SRV1_1.vhdx -Dynamic -SizeBytes $VHDSize -PhysicalSectorSizeBytes $PhysicalSectorSize
            New-VHD -path $VMpfadCore\KMS-SRV1_2.vhdX -Dynamic -SizeBytes $VHDSize -PhysicalSectorSizeBytes $PhysicalSectorSize
    
        #Neue virtuelle Maschine CoreServer erstellen
            New-VM -name $nameCore -Generation 2 -VHDPath $VMpfadCore\KMS-SRV1_0.vhdx -MemoryStartupBytes $SRAM -SwitchName $VMSIntern -Path $VMpfadCore
            Set-VMMemory -VMName $nameCore -DynamicMemoryEnabled $false
            Set-VMProcessor -VMName $nameCore -count 2
    
        #Zusätzliche Festplatten zur virtuellen Maschine CoreServer (KMS-SRV1) hinzufügen
            Add-VMHardDiskDrive -ControllerType SCSI -VMName $nameCore -Path $VMpfadCore\KMS-SRV1_1.vhdx
            Add-VMHardDiskDrive -ControllerType SCSI -VMName $nameCore -Path $VMpfadCore\KMS-SRV1_2.vhdx

        #SCSI Controller und DVD-Laufwerke
            Add-VMScsiController -VMName $nameCore 
            Add-VMDvdDrive -VMName $nameCore -ControllerNumber 1



# FIREWALL EINRICHTEN------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

        #Festplatten Clone für Firewall erstellen
            New-VHD -path $VMpfadFirewall\KMS-Firewall.vhdx -ParentPath $ParentFIREWALLpfad

        #Neue virtuelle Maschine "Firewall" erstellen
            New-VM -name $nameFW -Generation 1 -VHDPath $VMpfadFirewall\KMS-Firewall.vhdx -MemoryStartupBytes 512MB -Path $VMpfadFirewall -SwitchName $VMSIntern
            Add-VMNetworkAdapter -VMName $nameFW -SwitchName $VMSExtern



# CLIENT EINRICHTEN------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

        #Festplatten Clone für Client 1 erstellen
            New-VHD -path $VMpfadClient\KMS-CL1.vhdx -ParentPath $ParentCLIENTpfad

        #Neue virtuelle Maschine Client 1 (KMS-CL1) erstellen
            New-VM -name $nameClient -Generation 2 -VHDPath $VMpfadClient\KMS-CL1.vhdx -MemoryStartupBytes $CRAM -SwitchName $VMSIntern -Path $VMpfadClient
            Add-VMDvdDrive -VMName $nameClient -ControllerNumber 0



# Prüfpunkt----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

        #Prüfpunkt erstellen für die Maschinen "KMS-DC1" & "KMS-SRV1"
            $VMCheckPoint | Get-VM | Checkpoint-VM -SnapshotName "KMS-Base"


# VM Server und Client starten----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            Start-VM $nameDC
            Start-VM $nameCore
            Start-VM $nameClient
            Start-VM $nameFW
