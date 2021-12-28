#USER
    $csvFile = "c:\user.csv"
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
    $OUpath = "dc=$DomSub,dc=$DomTop"
# CREATE USER        foreach ($i in $users) {
                $UserLogin = $i.LastName + "." + $i.FirstName
                $DisplayName = $i.FirstName + "." + $i.LastName
                $SecurePass = ConvertTo-SecureString $i.DefaultPassword -AsPlainText -Force
                $OU = "ou=" + $i.Path + "," + $OUpath
                $LDAPou = "LDAP://$OU"
                $GrpSec = $i.Path + "-Mgmt"
                $GrpMail = $i.Path + "-Mail"
#OU überprüfen, wenn existiert überspringen, sonst erstellen    
                $ou_exists = [adsi]::Exists($LDAPou)
                if (-not $ou_exists){
                            New-ADOrganizationalUnit -Name $i.path -Path $OUpath -ProtectedFromAccidentalDeletion $true
                            New-ADGroup $GrpSec -path $OU -GroupCategory Security -GroupScope Global
                            New-ADGroup $GrpMail -Path $OU -GroupCategory Distribution -GroupScope Universal
                }
#User erstellen                New-ADUser `                    -name $DisplayName `                    -givenname $i.LastName `                    -Surname $i.FirstName `                    -DisplayName $DisplayName `                    -Department $i.Department `                    -Path $OU `                    -UserPrincipalName ($UserLogin + "@" + $DomName) `                    -SamAccountName $UserLogin `                    -AccountPassword $SecurePass `                    -ChangePasswordAtLogon:$True `                    -Enabled $true
#Ordner erstellen & freigeben
                $SMBpath = "E:\" + $i.path + "\"
                New-Item -Path ($SMBpath + $UserLogin) -ItemType "Directory"
                New-SmbShare -name $UserLogin -Path ($SMBpath + $UserLogin) -FullAccess $UserLogin, ($DomSub + "\" + $DomAdminEn)
#Sicherheitsgruppe zuweisen
                Add-ADGroupMember $GrpSec -Members $UserLogin
                Add-ADGroupMember $GrpMail -Members $UserLogin
}