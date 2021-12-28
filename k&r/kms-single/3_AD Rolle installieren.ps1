﻿#################################################################
#                                                               #
#              Active Directory Rolle installieren              #
#                                                               #
#################################################################



$domain = "kmsystem.local"
$netbiosname = "KMSYSTEM"
$mode = "7"
$password = "Pa55w.rd" | ConvertTo-SecureString -AsPlainText -Force

#Rolle installieren
        Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
#Settings
        Import-Module ADDSDeployment
        Install-ADDSForest `