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
            $ParentDCpfad = "D:\hyperV\base\WindowsServer2016_EN_Desktop_TMP.vhdx"
        #Pfade VMs        
            $VMpfadDC = "D:\hyperV\Skynet\SN-CL1"

        #Netadapter
            $VMSIntern = "SN-Intern"
        #Maschinen
            $nameSRV = "SN-SRV1"
            $RAM = 2GB
            $CPUcount = 2
        #Zusätzliche Festplatten
            $VHDcount = 4
            $VHDsize = 100GB

        #Nicht ändern!  
            $VHDpath = $VMpfadDC + "\" + $nameSRV + "_0.vhdx"
            $ExtraVHDpath = $VMpfadDC + "\" + $nameSRV + "_"            
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
            New-VM -name $nameSRV -Generation 2 -VHDPath $VHDpath -MemoryStartupBytes $RAM -SwitchName $VMSIntern -Path $VMpfadDC
            Set-VMMemory -VMName $nameSRV -DynamicMemoryEnabled $false
            Set-VMProcessor -VMName $nameSRV -count $CPUcount

        #Zusätzliche Festplatten hinzufügen   
            if ($VHDcount -eq 0){write-host "Keine zusätzlichen Festplatten"}
            else {for ($i=1; $i -le $VHDcount; $i++){
                            $zVHD = $ExtraVHDpath + $i +".vhdx"
                            New-VHD -path $zVHD -Dynamic -SizeBytes $VHDsize -PhysicalSectorSizeBytes $PhysicalSectorSize
                            Add-VMHardDiskDrive -ControllerType SCSI -VMName $nameDC -Path $zVHD}}

        #SCSI Controller und DVD-Laufwerke
            Add-VMScsiController -VMName $nameSRV
            Add-VMDvdDrive -VMName $nameSRV -ControllerNumber 1

# Prüfpunkt & Start---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

        #Prüfpunkt erstellen
            $VMCheckPoint | Get-VM | Checkpoint-VM -SnapshotName "SN-Base"
	#Starten
            Start-VM $nameSRV

