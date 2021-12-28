#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
                 ########             #########               ###                   ACHTUNG!  
               ###########        ##################         #                      CSV-FILE PFAD "C:userCSV.csv" muss korrekt sein
             #############     ######################        #                      
            ##############    ########################        ###  
          ################    ##########################                            Variablen übergeben
         #################    ############    ##########     ####              DC - Partitionierung / IP-Vergabe
       ###################     ##########    ###########      #  #             DC - Active Directory Installation & Konfiguration
     ########### #########                 #############      ###              DC - DNS Konfiguration
   ############  #########              ###############       # ##           CORE - Partitionierung / IP-Vergabe / Domäne beitreten
  ###########    #########            ################                    DC/CORE - DHCP installation und Konfiguration
 ###########     #########          ###############           ##          DC/CORE - Authorisieren / Core zum DC-ServerManager hinzufügen         
############################     ###############             #  #              DC - User anlegen, OU´s und Sicherheitsgruppen erstellen und User zuweisen          
#############################  ###############               ####         DC/CORE - Windows Server Backup installieren
############################# ###############                #  #              DC - Windows Resourcen Manager installieren
######################################################                       CORE - Druckerserver installieren
 ######################################################      #  #
                #########   ###########################       ##
                #########   ###########################       #
                 #######     #########################       #
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

#Maschinen
   $VM_DC = "SN-DC1"
   $VM_Core = "SN-SV2"
#Domain
   $DomSub = "skynet"
   $DomTop = "local"

#Credential
   $Username = "Administrator"
   $Password = "Pa55w.rd" | ConvertTo-SecureString -AsPlainText -Force
   $Credential = New-Object System.Management.Automation.PSCredential($Username,$password)
#CredentialDomain
   $DomainName = ($DomSub + "." + $DomTop)
   $Username = "Administrator"
   $DomainAdmin = ($DomSub + "\" + $Username)
   $Password = "Pa55w.rd" | ConvertTo-SecureString -AsPlainText -Force
   $CredentialDom = New-Object System.Management.Automation.PSCredential($DomainAdmin,$password)

#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#DC - PARTITIONIERUNG / IP-VERGABE----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Invoke-Command -VMname $VM_DC {
                                $IPAddress = "192.168.10.1"
                                $Netmask = "24"
                                $DefaultGateway = "192.168.10.254"
                                $DNSServer = "192.168.10.1"
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
                                Rename-Computer -NewName $ServerName -Restart
                                  
} -Credential $Credential

sleep -Seconds 60

#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#DC - ACTIVE DIRECTORY INSTALL--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
Invoke-Command -VMname $VM_DC {

                                $domain = "skynet.local"
                                $netbiosname = "SKYNET"
                                $mode = "7"
                                $password = "Pa55w.rd" | ConvertTo-SecureString -AsPlainText -Force

                            #Rolle installieren
                                Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

                            #Settings
                                Import-Module ADDSDeployment
                                Install-ADDSForest `                                -CreateDnsDelegation:$false `                                -DatabasePath "D:\AD\NTDS" `                                -DomainMode "$mode" `                                -DomainName "$domain" `                                -DomainNetbiosName $netbiosname `                                -ForestMode "$mode" `                                -InstallDns:$true `                                -LogPath "D:\AD\NTDS" `                                -NoRebootOnCompletion:$false `                                -SafeModeAdministratorPassword:$password `                                -SysvolPath "D:\AD\SYSVOL" `                                -Force:$true
                                  
} -Credential $Credential

# Warten während GPOs geladen werden

sleep -Seconds 450

#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# DNS am DC einrichten----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      
Invoke-Command -VMname $VM_DC {
                
                                    $NetworkID = "192.168.10.0/24"
                                    $dnsIP = "192.168.10.1"
                                    $dnsFWD = "10.1.5.80"
                                        
                                #Standart DNS IPv6 löschen (::1)
                                    Set-DnsClientServerAddress -InterfaceAlias "LAN-DOM" -ResetServerAddresses

                                #DNS einrichten
                                    Get-DnsServerZone
                                    Add-DnsServerPrimaryZone -NetworkID $NetworkID -ReplicationScope Domain -DynamicUpdate Secure -PassThru
                                    ipconfig /registerdns
                                    Set-DnsClientServerAddress -InterfaceAlias "LAN-DOM" -ServerAddresses $dnsIP

                                #Weiterleitung
                                    Set-DnsServerForwarder -IPAddress $dnsFWD -PassThru
                             
                                # DC für DHCP Installation am Core vorbereiten / DHCP-RSAT installieren / All-Server OU erstellen
                                    Install-WindowsFeature -Name RSAT-DHCP
                                    New-ADOrganizationalUnit -Name "All-Server"
} -Credential $CredentialDom

#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# CORE - PARTITIONIERUNG / IP-VERGABE / DOMÄNE BEITRETEN------------------------------------------------------------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Invoke-Command -VMname $VM_Core {

                                    $IPAddress = "192.168.10.2"
                                    $Netmask = "24"
                                    $DefaultGateway = "192.168.10.254"
                                    $DNSServer = "192.168.10.1"
                                    $ServerName = "SN-Core"
                                    $AdapterName = "LAN-DOM"
                                    $CName = "System"
                                    $DName = "DB-Mail"
                                    $EName = "Mail-Daten"


                                #Netzwerkadapter / IP-Adresse
                                    $vmnic = Get-NetAdapter -Physical | where {$_.ifindex}
                                    Get-NetAdapter -InterfaceIndex $vmnic.ifIndex | Rename-NetAdapter -NewName $AdapterName
                                    New-NetIPAddress -IPAddress $IPAddress -DefaultGateway $DefaultGateway -PrefixLength $Netmask -InterfaceIndex $vmnic.ifIndex
                                    Set-DnsClientServerAddress -InterfaceIndex $vmnic.ifIndex -ServerAddresses $DNSServer

                                #DVD-Laufwerksbuchstabe von D: auf Z: ändern
                                    $drive = Get-WmiObject -Class win32_volume -Filter "Driveletter = 'd:'"
                                    Set-WmiInstance -Input $drive -Arguments @{Driveletter ="Z:";}

                                 #Partitionierung
                                    New-Partition -DiskNumber 0 -DriveLetter D -Size 25GB
                                    New-Partition -DiskNumber 0 -DriveLetter E -UseMaximumSize

                                #Formatieren und Laufwerksbuchstabe zuweisen
                                    Format-Volume -DriveLetter D -FileSystem NTFS -NewFileSystemLabel $DName -Confirm:$false
                                    Format-Volume -DriveLetter E -FileSystem NTFS -NewFileSystemLabel $EName -Confirm:$false
                                    Set-Volume -DriveLetter C -NewFileSystemLabel $CName

                                #Servername ändern & Domäne beitreten (Die OU "All-Server" muss erstellt worden sein)
                                    $DomTop = "local"
                                    $DomSub = "skynet"
                                    $DomainName = ($DomSub + "." + $DomTop)
                                    $ServerOU = "All-Server"
                                    $Username = "Administrator"
                                    $ouPath = ("OU=$ServerOU" + "," + "DC=$DomSub" + "," + "DC=$DomTop")
                                    $DomainAdmin = ($DomSub + "\" + $Username)
                                    $Password = "Pa55w.rd" | ConvertTo-SecureString -AsPlainText -Force
                                    $Credential = New-Object System.Management.Automation.PSCredential($DomainAdmin,$password)

                                    Add-Computer -NewName $ServerName -DomainName $DomainName -Credential $Credential -OUPath $ouPath -restart

} -Credential $CredentialDom

sleep -Seconds 10
 
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# CORE - DHCP INSTALL-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Invoke-Command -VMName $VM_DC {Install-WindowsFeature -Name DHCP –IncludeManagementTools} -Credential $CredentialDom
   
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# DC - AUTHORISIEREN------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    
Invoke-Command -VMname $VM_DC {

                                    $CoreIP = "192.168.10.1"
                                    $CoreDomainName = "SN-DC01.skynet.local"
                                    Add-dhcpServerInDC -DnsName $CoreDomainName -IPAddress $CoreIP
                                    Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Servermanager\Roles\12 -Name ConfigurationState -Value 2
                                    Add-DhcpServerSecurityGroup -ComputerName "SN-DC01.skynet.local"

} -Credential $CredentialDom

#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#CORE - DHCP konfigurierien-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Invoke-Command -VMname $VM_DC {   
 
                                    $StartIP = "192.168.10.20"
                                    $EndIP = "192.168.10.200"
                                    $Scope = "Sky-Net"
                                    $Netmask = "255.255.255.0"
                                    $GatewayIP = "192.168.10.254"
                                    $DNSServerIP = "192.168.10.1"
                                    $DHCPServerIP = "192.168.10.1"
                                    $DNSDomain="skynet.local"

                                #DHCP Installation 
                                    Install-WindowsFeature -Name DHCP
                                #DHCP Konfiguration
                                    Set-DhcpServerv4Binding -BindingState $true -interfaceAlias "LAN-DOM"
                                #Bereich setzen
                                    Add-dhcpServerv4Scope -Name $Scope -StartRange $StartIP -EndRange $EndIP -SubnetMask $Netmask
                                #DNS / Gateway mitteilen
                                    Set-DhcpServerV4OptionValue -DnsDomain $DNSDomain -DnsServer $DNSServerIP -Router $GatewayIP
                                    Set-DhcpServerv4Scope -ScopeId $DHCPServerIP -LeaseDuration 1.08:00:00
                                #Restart DHCP Service
                                    Restart-Service -Name DHCPServer -Force
} -Credential $CredentialDom

#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#DC - Zum ServerManager hinzufügen----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Invoke-Command -VMname $VM_DC {

                                get-process ServerManager | stop-process –force
                                $file = get-item "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\ServerManager\ServerList.xml"
                                copy-item –path $file –destination $file-backup –force
                                $xml = [xml] (get-content $file )
                                $newserver = @($xml.ServerList.ServerInfo)[0].clone()
                                    $newserver.name = “SN-Core.Skynet.local”
                                    $newserver.lastUpdateTime = “0001-01-01T00:00:00”
                                    $newserver.status = “2”
                                $xml.ServerList.AppendChild($newserver)
                                $xml.Save($file.FullName)
                                start-process –filepath $env:SystemRoot\System32\ServerManager.exe –WindowStyle Maximized

} -Credential $CredentialDom

sleep -Seconds 10

#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#DC - User hinzufügen-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Invoke-Command -VMName $VM_DC {
                #USER
                    $csvFile = "C:\userCSV.csv"
                    $users = Import-CSV $csvfile
                #DOMAIN
                    $DomName = $env:USERDNSDOMAIN
                    $DomSplit = $DomName.Split(".")
                    $DomSub = $DomSplit[0]
                    $DomTop = $DomSplit[1]
                #DOMAINADMIN
                    $DomAdminEn = "Domain Admins"
                    $DomAdminDe = "Domänen-Admins"
                    $EveryoneDe = "Jeder"
                    $EveryoneEn = "Everyone"
                #OGANIZATIONAL UNIT
                    $OUpath = "dc=$DomSub,dc=$DomTop"    # GRuppenrichtlinien erstellen                    New-GPO -Name "NoLogon"
                    New-GPO -name "UserDevice"    # CREATE USER                      foreach ($i in $users) {
                                $UserLogin = $i.LastName + "." + $i.FirstName
                                $DisplayName = $i.FirstName + "." + $i.LastName
                                $SecurePass = ConvertTo-SecureString $i.DefaultPassword -AsPlainText -Force
                                $OU = "ou=" + $i.Path + "," + $OUpath
                                $LDAPou = "LDAP://$OU"
                                $GrpSec = $i.Path + "-Mgmt"
                                $GrpMail = $i.Path + "-Mail"
                #OU überprüfen, wenn existiert überspringen, sonst erstellen  
                #GPO´s mit OU´s verknüpfen
                                $ou_exists = [adsi]::Exists($LDAPou)
                                if (-not $ou_exists){   New-ADOrganizationalUnit -Name $i.path -Path $OUpath -ProtectedFromAccidentalDeletion $true
                                                        New-ADGroup $GrpSec -path $OU -GroupCategory Security -GroupScope Global
                                                        New-ADGroup $GrpMail -Path $OU -GroupCategory Distribution -GroupScope Universal
                                                        New-GPLink -Name "NoLogon" -Target $OU
                                                        New-GPLink -Name "UserDevice" -Target $OU

                                                        #$SMBname = $i.path + "_shared"
                                                        #$SMBpathGRP = "E:\" + $i.path + "_shared"
                                                        #New-Item -Path $SMBpathGRP -ItemType "Directory"
                                                        #New-SmbShare -name $SMBname -Path $SMBpathGRP -FullAccess $GrpSec, ($DomSub + "\" + $DomAdminEn)
                                                        }
                #User erstellen                                New-ADUser `                                    -name $DisplayName `                                    -givenname $i.LastName `                                    -Surname $i.FirstName `                                    -DisplayName $DisplayName `                                    -Department $i.Department `                                    -Path $OU `                                    -UserPrincipalName ($UserLogin + "@" + $DomName) `                                    -SamAccountName $UserLogin `                                    -AccountPassword $SecurePass `                                    -ChangePasswordAtLogon:$True `                                    -Enabled $true
                #Ordner erstellen & freigeben
                                $SMBpath = "E:\" + $i.path + "\" + $i.LastName + "_" + $i.FirstName
                                New-Item -Path $SMBpath -ItemType "Directory"
                                New-SmbShare -name $UserLogin -Path $SMBpath -FullAccess $UserLogin, ($DomSub + "\" + $DomAdminEn)
                #Sicherheitsgruppe zuweisen
                                Add-ADGroupMember $GrpSec -Members $UserLogin
                                Add-ADGroupMember $GrpMail -Members $UserLogin
                         }

} -Credential $CredentialDom

#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# DC& CORE - Weitere Rollen hinzufügen------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# DC
Invoke-Command -VMName $VM_DC {                                
                                # FS-Resource-Manager installieren
                                    Install-WindowsFeature -Name FS-Resource-Manager -IncludeManagementTools
                                
                                # WindowsServerBackup installieren
                                    Install-WindowsFeature Windows-Server-Backup
} -Credential $CredentialDom

# CORE
Invoke-Command -VMName $VM_Core {
                                # WindowsServerBackup installieren
                                    Install-WindowsFeature Windows-Server-Backup
                                # Drucker Server installieren
                                    Install-WindowsFeature Print-Server
                                    Install-WindowsFeature Print-Services
                                    netsh advfirewall firewall set rule group="Datei- und Druckerfreigabe" new enable=Yes
                                    
} -Credential $CredentialDom

# DC - Read me erstellen (DC)
Invoke-Command -VMName $VM_DC {  
        # infos in die Read me         
            dir env: | sort name
            Get-Content Env:computername
            Get-Content Env:userprofile
            Get-Content Env:username
        #Variablen
            $UserName = gc env:username
            $DCname = gc env:computername
            $DomName = $env:USERDNSDOMAIN
            $DomSplit = $DomName.Split(".")
            $DomSub = $DomSplit[0]
            $DomTop = $DomSplit[1]
        #DOMAINADMIN
            $DomUser = $DomSub + "\" + $UserName

} -Credential $CredentialDom
