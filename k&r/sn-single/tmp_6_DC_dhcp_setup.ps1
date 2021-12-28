##############################################
# temp-script von 6_DC_DHCP_setup_config.ps1 #
#        1 - DHCP Installation               #
#        2 - DHCP Konfiguration              #
#        3 - Bereich setzen                  #
#        4 - DNS / Gateway mitteilen         #
#        5 - Restart DHCP Service            #
##############################################
   
    $StartIP = "192.168.15.20"
    $EndIP = "192.168.15.200"
    $Scope = "SN-Range1"
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
    Set-DhcpServerv4Scope -ScopeId $DHCPServerIP -LeaseDuration 1.00:00:00

#Restart DHCP Service
    Restart-Service -Name DHCPServer -Force 