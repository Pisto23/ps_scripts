################################################
# HYPER-V - Virtuelle Maschinen aufsetzen      #
#      - HYPER-V Netadapter erstellen          #
#       - DOMAIN CONTROLLER einrichten         #
################################################

#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        #Administrator Powershell-Rechte
            Set-ExecutionPolicy Unrestricted

# VARIABLEN ÜBERGEBEN-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

        #Pfade Parents
            $ParentDCpfad = "D:\Base\WindowsServer2016_de_tmp.vhdx"
        #Pfade VMs        
            $VMpfadDC = "D:\VirtualMaschines\Hyper-V\Azeroth\SN-MySQL"

        #Netadapter
            $VMSIntern = "WOW-Intern"
        #Maschinen
            $nameDC = "WOW-MySQL"
            $RAM = 2GB
            $CPUcount = 2
        #Zusätzliche Festplatten
            $VHDcount = 4
            $VHDsize = 100GB

        #Nicht ändern!  
            $VHDpath = $VMpfadDC + "\" + $nameDC + "_0.vhdx"
            $ExtraVHDpath = $VMpfadDC + "\" + $nameDC + "_"            
            $VMCheckPoint = $nameDC
            $VHDBlockSize = 1MB
            $PhysicalSectorSize = "4096"

# HYPER-V Netadapter erstellen, Extern und Intern--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    
            $Netz = Get-NetAdapter -physical | where status -eq "up"
            $TestSwitch = Get-VMSwitch -name $VMSIntern -ErrorAction SilentlyContinue; if ($TestSwitch.Count -eq 0){New-VMSwitch -Name $VMSIntern -SwitchType Internal}    

# DOMAIN CONTROLLER EINRICHTEN------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

        #Festplatten Clone für Domain Controller erstellen
            New-VHD -path $VHDpath -ParentPath $ParentDCpfad -PhysicalSectorSizeBytes $PhysicalSectorSize

        
#Neue virtuelle Maschine erstellen
            New-VM -name $nameDC -Generation 2 -VHDPath $VHDpath -MemoryStartupBytes $RAM -SwitchName $VMSIntern -Path $VMpfadDC
            Set-VMMemory -VMName $nameDC -DynamicMemoryEnabled $false
            Set-VMProcessor -VMName $nameDC -count $CPUcount

        #Zusätzliche Festplatten hinzufügen   
            if ($VHDcount -eq 0){write-host "Keine zusätzlichen Festplatten"}
            else {for ($i=1; $i -le $VHDcount; $i++){
                            $zVHD = $ExtraVHDpath + $i +".vhdx"
                            New-VHD -path $zVHD -Dynamic -SizeBytes $VHDsize -PhysicalSectorSizeBytes $PhysicalSectorSize
                            Add-VMHardDiskDrive -ControllerType SCSI -VMName $nameDC -Path $zVHD}}

        #SCSI Controller und DVD-Laufwerke
            Add-VMScsiController -VMName $nameDC
            Add-VMDvdDrive -VMName $nameDC -ControllerNumber 1

# Prüfpunkt & Starten----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

        #Prüfpunkt erstellen für die Maschinen "SN-DC1" & "SN-SRV1"
            $VMCheckPoint | Get-VM | Checkpoint-VM -SnapshotName "SN-Base"
	#Starten
	    Start-VM $nameDC

