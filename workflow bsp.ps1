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
            $VMPath = "D:\Users\ATN_65\Hyper-V\Skynet"
            $VMBase = "E:\Base"
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
            $VMpfadDC = "D:\users\ATN_65\Hyper-V\Skynet\SN-DC1\"
            $VMpfadCore = "D:\users\ATN_65\Hyper-V\Skynet\SN-SRV1\"
            $VMpfadFirewall =  "D:\users\ATN_65\Hyper-V\Skynet\SN-Firewall\"
            $VMpfadClient =  "D:\users\ATN_65\Hyper-V\Skynet\SN-CL1\"
        #CP´s
            $VMCheckPoint = "SN-CL1","SN-DC1","SN-SRV1"

# HYPER-V Netadapter erstellen, Extern und Intern--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    
            $Netz = Get-NetAdapter -physical | where status -eq "up"
            $TestSwitch = Get-VMSwitch -name $VMSIntern -ErrorAction SilentlyContinue; if ($TestSwitch.Count -eq 0){New-VMSwitch -Name $VMSIntern -SwitchType Internal}
    
# DOMAIN CONTROLLER EINRICHTEN------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



Invoke-Command -VMname $VM_DC {
workflow Rename-And-Reboot {
    param ([string]$Name)
                $IPAddress = "192.168.15.1"
                $Netmask = "20"
                $DefaultGateway = "192.168.15.254"
                $DNSServer = "192.168.15.1"
                [string]$ServerName = "SN-DC01"
                [string]$AdapterName = "LAN-DOM"
                $CName = "System"
                $DName = "AD-Daten"
                $EName = "Daten"
            #Netzwerkadapter / IP-Adresse
                $vmnic = Get-NetAdapter -Physical | where {$_.ifIndex}
                Get-NetAdapter -interfaceindex $vmnic.ifIndex | Rename-NetAdapter -NewName $AdapterName
                New-NetIPAddress -IPAddress $IPAddress -DefaultGateway $DefaultGateway -PrefixLength $Netmask -InterfaceIndex $vmnic.ifIndex
                Set-DnsClientServerAddress -InterfaceIndex $vmnic.ifIndex -ServerAddresses $DNSServer
            #DVD-Laufwerksbuchstabe von D: auf Z: ändern 
                $drive = Get-WmiObject -Class win32_volume -Filter "Driveletter = 'd:'"
                Set-WmiInstance -input $drive -Arguments @{Driveletter="Z:";}
            #Partitionierung, Laufwerksbuchstabe
                New-Partition -DiskNumber 0 -DriveLetter D -Size 15GB
                New-Partition -DiskNumber 0 -DriveLetter E -UseMaximumSize
            #Formatieren
                Format-Volume -DriveLetter D -FileSystem NTFS -NewFileSystemLabel $DName -Confirm:$false
                Format-Volume -DriveLetter E -FileSystem NTFS -NewFileSystemLabel $EName -Confirm:$false
                Set-Volume -DriveLetter C -NewFileSystemLabel $CName
            #Servername ändern & Restart
                Rename-Computer -NewName $ServerName 
    Restart-Computer -Wait
                $domain = "skynet.local"
                $netbiosname = "SKYNET"
                $mode = "7"
                $password = "Pa55w.rd" | ConvertTo-SecureString -AsPlainText -Force
            #Rolle installieren
                Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
            #Settings
                Import-Module ADDSDeployment
                Install-ADDSForest `                -CreateDnsDelegation:$false `                -DatabasePath "D:\AD\NTDS" `                -DomainMode "$mode" `                -DomainName "$domain" `                -DomainNetbiosName $netbiosname `                -ForestMode "$mode" `                -InstallDns:$true `                -LogPath "D:\AD\NTDS" `                -NoRebootOnCompletion:$false `                -SafeModeAdministratorPassword:$password `                -SysvolPath "D:\AD\SYSVOL" `                -Force:$true
    }
} -Credential $Credential
