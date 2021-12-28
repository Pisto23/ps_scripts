#######################################################
# DOMAIN CONTROLLER                                   #
#     - Netzwerkadapter / IP-Adresse                  #
#      - DVD-Laufwerksbuchstabe von D: auf Z: ändern  #
#       - Partitionierung, Laufwerksbuchstabe         #
#        - Formatieren                                #
#         - Servername ändern & Restart               #
#######################################################


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