#######################################################
# CORE-Server Setup                                   #
#    - Netzwerkadapter / IP-Adresse                   #
#     - DVD-Laufwerksbuchstabe von D: auf Z: ändern   #
#      - Partitionierung                              #
#       - Formatieren und Laufwerksbuchstabe zuweisen #
#        - Servername ändern & Domäne beitreten       #
#######################################################

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
