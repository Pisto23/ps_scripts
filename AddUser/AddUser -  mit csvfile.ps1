##############################################
#  AUTOMATISIERUNG                           #
#      - CSV file auslesen und user anlegen  #
#      - OU´s zuweisen                       #
#      - Gruppen zuweisen                    #
#      - SMB- Ordner erstellen & freigeben   #
##############################################

#USER
    $csvFile = "c:\test.csv"
    $users = Import-CSV $csvfile
#DOMAIN
    $DomName = $env:USERDNSDOMAIN
    $DomSplit = $DomName.Split(".")
    $DomSub = $DomSplit[0]
    $DomTop = $DomSplit[1]
#DOMAINADMIN
    $DomAdminEn = "Domain Admins"
    $DomAdminDe = "Domänen-Admin"
    $EveryoneDe = "Jeder"
    $EveryoneEn = "Everyone"
#OGANIZATIONAL UNIT
    $OU = "ou=sales,dc=skynet,dc=local"
    $OUname = "sales"
    $OUpath = "dc=skynet,dc=local"
    $path = "E:\Sales\"
#GROUP
    $SalesGrpSec = "Sales-Mgmt"
    $SalesMail = "Sales-Mail"

#################################################################################################################################################################################################################################

# OU erstellen
        New-ADOrganizationalUnit -Name $OUname -Path $OUpath -ProtectedFromAccidentalDeletion $true

# Create Groups
        New-ADGroup $SalesGrpSec -path $OU -GroupCategory Security -GroupScope Global
        New-ADGroup $SalesMail -Path $OU -GroupCategory Distribution -GroupScope Universal

# Create Users in Sales
        foreach ($i in $users) {
                $UserLogin = $i.LastName + "." + $i.FirstName
                $DisplayName = $i.FirstName + "." + $i.LastName
                $SecurePass = ConvertTo-SecureString $i.DefaultPassword -AsPlainText -Force
        New-ADUser `        -name $i.FirstName `        -givenname $i.LastName `        -Surname $i.FirstName `        -DisplayName $DisplayName `        -Department $i.Department `        -Path $OU `        -UserPrincipalName ($UserLogin + "@" + $DomName) `        -SamAccountName $UserLogin `        -AccountPassword $SecurePass `        -ChangePasswordAtLogon:$True `        -Enabled $true

    #Ordner erstellen & freigeben
        New-Item -Path ($path + $UserLogin) -ItemType "Directory"
        New-SmbShare -name $UserLogin -Path ($path + $UserLogin) -FullAccess $UserLogin, ($DomSub + "\" + $DomAdminEn)
    
    #Sicherheitsgruppe zuweisen
        $SalesGroup = Get-ADUser -SearchBase $OU -Filter *
        Add-ADGroupMember $SalesGrpSec -Members $SalesGroup
        Add-ADGroupMember $SalesMail -Members $SalesGroup
        }

#################################################################################################################################################################################################################################