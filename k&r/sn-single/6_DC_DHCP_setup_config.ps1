##############################################
#    1 - DHCP start script ausführen         #
#    2 - SRV01 Authorisien                   #
#    3 - SRV01 zum ServerManager hinzufügen  #
##############################################

Set-ExecutionPolicy remotesigned

$DHCPpath = "C:\IMPORT\tmp_6_DC_dhcp_setup.ps1"
$Sname = "SN-SRV01"
$ServerDomainName = "SN-SRV01.skynet.local"
$ServerIP = "192.168.15.2"

#SRV01 dem ServerManager hinzufügen  
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
 


#DHCP START SCRIPT 
    Invoke-Command -ComputerName $Sname -FilePath $DHCPpath

#SRV01 Authorisien
    Add-dhcpServerInDC -DnsName $ServerDomainName -IPAddress $ServerIP
    Set-ItemProperty –Path registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\ServerManager\Roles\12 –Name ConfigurationState –Value 2
    Set-DhcpServerv4DnsSetting -ComputerName "SN-SRV01.skynet.local" -DynamicUpdates "Always" -DeleteDnsRRonLeaseExpiry $True


   