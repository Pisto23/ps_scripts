#################################################################
#                                                               #
#                  CORE-Server DHCP install                     #
#                                                               #
#################################################################

    Enter-PSSession -ComputerName KMS-SRV01
#DHCP & RSAT installieren

    Set-ExecutionPolicy remotesigned

    Install-WindowsFeature -Name DHCP
    Install-WindowsFeature -Name RSAT-DHCP

#DHCP Konfiguration
    Set-DhcpServerv4Binding -BindingState $true -interfaceAlias "LAN-DOM"
    
    Exit-PSSession

    $CoreIP = "192.168.15.2"
    $CoreName = "KMS-SRV01.kmsystem.local"
    Add-dhcpServerInDC -DnsName $CoreName -IPAddress $CoreIP

    Enter-PSSession -ComputerName KMS-SRV01

#Bereich
    $StartIP = "192.168.15.20"
    $EndIP = "192.168.15.200"
    $Scope = "KMS-Range1"
    $Netmask = "255.255.255.0"
    Add-dhcpServerv4Scope -Name $Scope -StartRange $StartIP -EndRange $EndIP -SubnetMask $Netmask

#DNS / Gateway
    $Gateway = "192.168.15.254"
    $DNS = "192.168.15.1"
    Set-DhcpServerv4OptionValue -OptionId 6 -value $DNS
    Set-DhcpServerv4OptionValue -OptionId 3 -value $Gateway

    #Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Servermanager\Roles\12 -Name ConfigurationState -Value 2

    Restart-Service -Name DHCPServer -Force
