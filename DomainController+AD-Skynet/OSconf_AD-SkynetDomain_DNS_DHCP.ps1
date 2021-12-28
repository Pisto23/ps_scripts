########################################################################
# Automatisierung                                                      #
#        - DC - PARTITIONIERUNG / IP-VERGABE                           #
#         - DC - ACTIVE DIRECTORY INSTALL                              #
#          - DC - DNS SETUP                                            #
#           - CORE - PARTITIONIERUNG / IP-VERGABE / DOMÄNE BEITRETEN   #
#            - DC/CORE - DHCP INSTALL & CONFIG                         #
#             - DC/CORE - AUTHORISIEREN / ADD SRV TO SERVERMANAGER     #
########################################################################

#Maschinen
    $VM_DC = "SN-DC1"
    $VM_Core = "SN-SRV1"

#Credential
   $Username = "Administrator"
   $Password = "Pa55w.rd" | ConvertTo-SecureString -AsPlainText -Force
   $Credential = New-Object System.Management.Automation.PSCredential($Username,$password)

#CredentialDomain
   $DomTop = "local"
   $DomSub = "skynet"
   $DomainName = ($DomSub + "." + $DomTop)
   $Username = "Administrator"
   $DomainAdmin = ($DomSub + "\" + $Username)
   $Password = "Pa55w.rd" | ConvertTo-SecureString -AsPlainText -Force
   $CredentialDom = New-Object System.Management.Automation.PSCredential($DomainAdmin,$password)



#DC - PARTITIONIERUNG / IP-VERGABE----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Invoke-Command -VMname $VM_DC {
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
                                Rename-Computer -NewName $ServerName -Restart
                                  
} -Credential $Credential

sleep -Seconds 30


#DC - ACTIVE DIRECTORY INSTALL----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
   
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


# Warten während GPOs geladen werden----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

sleep -Seconds 390


# DNS am DC einrichten----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        
Invoke-Command -VMname $VM_DC {
                
                                    $NetworkID = "192.168.15.0/24"
                                    $dnsIP = "192.168.15.1"
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


# CORE - PARTITIONIERUNG / IP-VERGABE / DOMÄNE BEITRETEN---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    
Invoke-Command -VMname $VM_Core {

                                    $IPAddress = "192.168.15.2"
                                    $Netmask = "24"
                                    $DefaultGateway = "192.168.15.254"
                                    $DNSServer = "192.168.15.1"
                                    $ServerName = "SN-SRV01"
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
 

# CORE - DHCP INSTALL----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
   
Invoke-Command -VMName $VM_Core {Install-WindowsFeature -Name DHCP –IncludeManagementTools} -Credential $CredentialDom
   

#DC - AUTHORISIEREN----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    
Invoke-Command -VMname $VM_DC {

                                    $CoreIP = "192.168.15.2"
                                    $CoreDomainName = "SN-SRV01.skynet.local"
                                    Add-dhcpServerInDC -DnsName $CoreDomainName -IPAddress $CoreIP
                                    Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Servermanager\Roles\12 -Name ConfigurationState -Value 2
                                    Add-DhcpServerSecurityGroup -ComputerName "SN-SRV01.skynet.local"

} -Credential $CredentialDom


#CORE - DHCP konfigurierien----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Invoke-Command -VMname $VM_Core {   
 
                                    $StartIP = "192.168.15.20"
                                    $EndIP = "192.168.15.200"
                                    $Scope = "Skynet-T800-Net"
                                    $Netmask = "255.255.255.0"
                                    $GatewayIP = "192.168.15.254"
                                    $DNSServerIP = "192.168.15.1"
                                    $DHCPServerIP = "192.168.15.2"
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


#DC - Zum ServerManager hinzufügen----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Invoke-Command -VMname $VM_DC {

                                get-process ServerManager | stop-process –force
                                $file = get-item "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\ServerManager\ServerList.xml"
                                copy-item –path $file –destination $file-backup –force
                                $xml = [xml] (get-content $file )
                                $newserver = @($xml.ServerList.ServerInfo)[0].clone()
                                    $newserver.name = “SN-SRV01.Skynet.local”
                                    $newserver.lastUpdateTime = “0001-01-01T00:00:00”
                                    $newserver.status = “2”
                                $xml.ServerList.AppendChild($newserver)
                                $xml.Save($file.FullName)
                                start-process –filepath $env:SystemRoot\System32\ServerManager.exe –WindowStyle Maximized

} -Credential $CredentialDom