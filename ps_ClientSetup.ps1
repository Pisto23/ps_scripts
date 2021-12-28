﻿################################################
# HYPER-V - Virtuelle Maschinen aufsetzen      #
#          - CLIENT einrichten                 #
################################################

#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        #Administrator Powershell-Rechte
            Set-ExecutionPolicy Unrestricte

# VARIABLEN ÜBERGEBEN-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

#Pfade Parents
    $VMbase = "D:\base\Win10_CL_en_tmp.vhdx"
#Pfade VMs        
    $VMClientPath =  "D:\Vm-Client\Win10_TestClient"
    
#Netadapter
    $VMSIntern = "WLAN_Switch"
#Maschine
        $VMClient = "TestClient"
        $RAM = 4GB
    #Zusätzliche Festplatten
        $VHDcount = 0
        $VHDsize = 1000GB

#Nicht ändern!           
        #Vhdx Settings
            $VHDBlockSize = 1MB
            $PhysicalSectorSize = "4096"
        # vhdx Pfade
            $VHDpath = $VMClientPath + "\" + $VMClient + "_0.vhdx"
            $ExtraVHDpath = $VMClientPath + "\" + $VMClient + "_"            
        #CP´s
            $VMCheckPoint = $VMClient

# HYPER-V Netadapter erstellen, Extern und Intern--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    
            $Netz = Get-NetAdapter -physical | where status -eq "up"
            $TestSwitch = Get-VMSwitch -name $VMSIntern -ErrorAction SilentlyContinue; if ($TestSwitch.Count -eq 0){New-VMSwitch -Name $VMSIntern -SwitchType Internal}

# CLIENT EINRICHTEN------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

        #Festplatten Clone für Client 1 erstellen
            New-VHD -path $VHDpath -ParentPath $VMbase
        #Neue virtuelle Maschine Client 1 (KMS-CL1) erstellen
            New-VM -name $VMClient -Generation 2 -VHDPath $VHDpath -MemoryStartupBytes $RAM -SwitchName $VMSIntern -Path $VMClientPath
            Add-VMDvdDrive -VMName $VMClient -ControllerNumber 0
        #Zusätzliche Festplatten   
            if ($VHDcount -eq 0){write-host "Keine zusätzlichen Festplatten"}
            else {
                for ($i=1; $i -le $VHDcount; $i++){
                            $zVHD = $ExtraVHDpath + $i +".vhdx"
                            New-VHD -path $zVHD -Dynamic -SizeBytes $VHDsize -PhysicalSectorSizeBytes $PhysicalSectorSize
                            Add-VMHardDiskDrive -ControllerType SCSI -VMName $VMClient -Path $zVHD}}
        
# Prüfpunkt & Client starten---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        
        #Prüfpunkt
            $VMCheckPoint | Get-VM | Checkpoint-VM -SnapshotName "Base"
        #Start
            Start-VM $VMClient
