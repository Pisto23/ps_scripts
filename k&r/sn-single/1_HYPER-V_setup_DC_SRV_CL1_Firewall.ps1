################################################
# HYPER-V - Virtuelle Maschinen aufsetzen      #
#     - Variablen übergebn                     #
#      - HYPER-V Netadapter erstellen          #
#       - DOMAIN CONTROLLER einrichten         #
#        - CORE einrichten                     #
#         - FIREWALL einrichten                #
#          - CLIENT einrichten                 #
#           - Prüfpunkt                        #
#            - VM Server und Client starten    #
################################################


#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        #Administrator Powershell-Rechte
            Set-ExecutionPolicy Unrestricted

        


# VARIABLEN ÜBERGEBEN-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        #UserProfile, Namen und Rechnername auslesen 
            dir env: | sort name
            Get-Content Env:computername
            Get-Content Env:userprofile
            Get-Content Env:username
        #Variablen
            $UserName = gc env:username
            $ComputerName = gc env:computername
            $UserProfile = $VMPath
            $VMPath = "E:\hyperV\Skynet"
            $VMBase = "E:\hyperV_ParentBase"
        #Netadapter
            $VMSIntern = "SN-Intern"
            $VMSExtern = "Extern"
        #Maschinen
            $nameDC = "SN-DC1"
            $nameCore = "SN-SRV1"
            $nameFW = "SN-Firewall"
            $nameClient = "SN-CL1"
            $CRAM = 1GB
            $SRAM = 2GB
            $DRAM = 2GB
            $VHDSize = 140GB
            $VHDBlockSize = 1MB
            $PhysicalSectorSize = "4096"
        #Pfade Parents
            $ParentDCpfad = "E:\hyperV_ParentBase\WinServ2016_de_dc_tmp.vhdx"
            $ParentCorepfad = "E:\hyperV_ParentBase\WinServ2016_de_core_tmp.vhdx"
            $ParentFIREWALLpfad = "E:\hyperV_ParentBase\endian_firewall_en_tmp.vhdx"
            $ParentCLIENTpfad = "E:\hyperV_ParentBase\Win10pro_de_client_tmp.vhdx"
        #Pfade VMs        
            $VMpfadDC = "E:\hyperV\Skynet\SN-DC1\"
            $VMpfadCore = "E:\hyperV\Skynet\SN-SRV1"
            $VMpfadFirewall =  "E:\hyperV\Skynet\SN-Firewall\"
            $VMpfadClient =  "E:\hyperV\Skynet\SN-CL1\"
        #CP´s
            $VMCheckPoint = "SN-CL1","SN-DC1","SN-SRV1"



# HYPER-V Netadapter erstellen, Extern und Intern--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    
            $Netz = Get-NetAdapter -physical | where status -eq "up"
            $TestSwitch = Get-VMSwitch -name $VMSIntern -ErrorAction SilentlyContinue; if ($TestSwitch.Count -eq 0){New-VMSwitch -Name $VMSIntern -SwitchType Internal}
            $TestSwitchEx = Get-VMSwitch -name $VMSExtern -ErrorAction SilentlyContinue; if ($TestSwitchEx.Count -eq 0){New-VMSwitch -Name $VMSExtern -NetAdapterName $Netz.Name} 
    


# DOMAIN CONTROLLER EINRICHTEN------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

        #Festplatten Clone für Domain Controller erstellen
            New-VHD -path $VMpfadDC\SN-DC1_0.vhdx -ParentPath $ParentDCpfad -PhysicalSectorSizeBytes $PhysicalSectorSize

        #Zusätzliche Festplatten Domain Controller erstellen
            New-VHD -path $VMpfadDC\SN-DC1_1.vhdx -Dynamic -SizeBytes $VHDSize -PhysicalSectorSizeBytes $PhysicalSectorSize
            New-VHD -path $VMpfadDC\SN-DC1_2.vhdx -Dynamic -SizeBytes $VHDSize -PhysicalSectorSizeBytes $PhysicalSectorSize

        #Neue virtuelle Maschine Domain Controller erstellen
            New-VM -name $nameDC -Generation 2 -VHDPath $VMpfadDC\SN-DC1_0.vhdx -MemoryStartupBytes $DRAM -SwitchName $VMSIntern -Path $VMpfadDC
            Set-VMMemory -VMName $nameDC -DynamicMemoryEnabled $false
            Set-VMProcessor -VMName $nameDC -count 4

    
        #Zusätzliche Festplatten zur virtuellen Maschine DC1 hinzufügen
            Add-VMHardDiskDrive -ControllerType SCSI -VMName $nameDC -Path $VMpfadDC\SN-DC1_1.vhdx
            Add-VMHardDiskDrive -ControllerType SCSI -VMName $nameDC -Path $VMpfadDC\SN-DC1_2.vhdx


        #SCSI Controller und DVD-Laufwerke
            Add-VMScsiController -VMName $nameDC
            Add-VMDvdDrive -VMName $nameDC -ControllerNumber 1



# CORE EINRICHTEN------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

        #Festplatten Clone für CoreServer erstellen
            New-VHD -path $VMpfadCore\SN-SRV1_0.vhdx -ParentPath $ParentCorepfad -PhysicalSectorSizeBytes $PhysicalSectorSize

        #Zusätzliche Festplatten CoreServer erstellen
            New-VHD -path $VMpfadCore\SN-SRV1_1.vhdx -Dynamic -SizeBytes $VHDSize -PhysicalSectorSizeBytes $PhysicalSectorSize
            New-VHD -path $VMpfadCore\SN-SRV1_2.vhdX -Dynamic -SizeBytes $VHDSize -PhysicalSectorSizeBytes $PhysicalSectorSize
    
        #Neue virtuelle Maschine CoreServer erstellen
            New-VM -name $nameCore -Generation 2 -VHDPath $VMpfadCore\SN-SRV1_0.vhdx -MemoryStartupBytes $SRAM -SwitchName $VMSIntern -Path $VMpfadCore
            Set-VMMemory -VMName $nameCore -DynamicMemoryEnabled $false
            Set-VMProcessor -VMName $nameCore -count 2
    
        #Zusätzliche Festplatten zur virtuellen Maschine CoreServer (KMS-SRV1) hinzufügen
            Add-VMHardDiskDrive -ControllerType SCSI -VMName $nameCore -Path $VMpfadCore\SN-SRV1_1.vhdx
            Add-VMHardDiskDrive -ControllerType SCSI -VMName $nameCore -Path $VMpfadCore\SN-SRV1_2.vhdx

        #SCSI Controller und DVD-Laufwerke
            Add-VMScsiController -VMName $nameCore 
            Add-VMDvdDrive -VMName $nameCore -ControllerNumber 1



# FIREWALL EINRICHTEN------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

        #Festplatten Clone für Firewall erstellen
            New-VHD -path $VMpfadFirewall\SN-Firewall.vhdx -ParentPath $ParentFIREWALLpfad

        #Neue virtuelle Maschine "Firewall" erstellen
            New-VM -name $nameFW -Generation 1 -VHDPath $VMpfadFirewall\SN-Firewall.vhdx -MemoryStartupBytes 512MB -Path $VMpfadFirewall -SwitchName $VMSIntern
            Add-VMNetworkAdapter -VMName $nameFW -SwitchName $VMSExtern



# CLIENT EINRICHTEN------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

        #Festplatten Clone für Client 1 erstellen
            New-VHD -path $VMpfadClient\SN-CL1.vhdx -ParentPath $ParentCLIENTpfad

        #Neue virtuelle Maschine Client 1 (KMS-CL1) erstellen
            New-VM -name $nameClient -Generation 2 -VHDPath $VMpfadClient\SN-CL1.vhdx -MemoryStartupBytes $CRAM -SwitchName $VMSIntern -Path $VMpfadClient
            Add-VMDvdDrive -VMName $nameClient -ControllerNumber 0



# Prüfpunkt----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

        #Prüfpunkt erstellen für die Maschinen "SN-DC1" & "SN-SRV1"
            $VMCheckPoint | Get-VM | Checkpoint-VM -SnapshotName "SN-Base"


# VM Server und Client starten----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            Start-VM $nameDC
            Start-VM $nameCore
            Start-VM $nameClient
            Start-VM $nameFW
