#################################################################
#  DNS am DC einrichten                                         #
#         - Standart DNS IPv6 löschen (::1)                     #
#          - DNS einrichten                                     #
#           - Weiterleitung                                     #
#            - DC für DHCP Installation am Core vorbereiten     #
#################################################################

#Standart DNS IPv6 löschen (::1)
        Set-DnsClientServerAddress -InterfaceAlias "LAN-DOM" -ResetServerAddresses

#DNS einrichten
        Get-DnsServerZone
        Add-DnsServerPrimaryZone -NetworkID 192.168.15.0/24 -ReplicationScope Domain -DynamicUpdate Secure -PassThru
        ipconfig /registerdns
        Set-DnsClientServerAddress -InterfaceAlias "LAN-DOM" -ServerAddresses 192.168.15.1

#Weiterleitung
        Set-DnsServerForwarder -IPAddress 10.1.5.80 -PassThru

# DC für DHCP Installation am Core vorbereiten / DHCP-RSAT installieren / All-Server OU erstellen
        Install-WindowsFeature -Name RSAT-DHCP
        New-ADOrganizationalUnit -Name "All-Server"
