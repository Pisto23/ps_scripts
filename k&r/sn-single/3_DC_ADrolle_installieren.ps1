########################################
#   ACTIVE DIRECTORY ROLLE             #
#        - Rolle installieren          #
#         - Konfigurieren              #
########################################

$domain = "skynet.local"
$netbiosname = "SKYNET"
$mode = "7"
$password = "Pa55w.rd" | ConvertTo-SecureString -AsPlainText -Force

#Rolle installieren
        Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

#Settings
        Import-Module ADDSDeployment
        Install-ADDSForest `        -CreateDnsDelegation:$false `        -DatabasePath "D:\AD\NTDS" `        -DomainMode "$mode" `        -DomainName "$domain" `        -DomainNetbiosName $netbiosname `        -ForestMode "$mode" `        -InstallDns:$true `        -LogPath "D:\AD\NTDS" `        -NoRebootOnCompletion:$false `        -SafeModeAdministratorPassword:$password `        -SysvolPath "D:\AD\SYSVOL" `        -Force:$true