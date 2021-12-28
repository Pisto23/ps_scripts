##############################################
#  AUTOMATISIERUNG                           #
#      - Userdaten eingeben                  #
#      - OU´s überprüfen/erstellen           #
#      - User anlegen                        #
#      - Gruppen zuweisen                    #
#      - SMB-Ordner erstellen & freigeben    #
##############################################

#-----> Variablen einlesen <-----#
Do {
    #USER EINGABE
        $Vorname = Read-Host -Prompt "Vorname eingeben"
        $Nachname = Read-Host -Prompt "Nachname eingeben"
        $Abteilung = Read-Host -Prompt "Abteilung eingeben"
        $Passwort = Read-Host -Prompt "Passwort eingeben" -AsSecureString
    #User/Displayname
        $UserLogin = $Nachname + "." + $Vorname
        $DisplayName = $Vorname + "." + $Nachname
        $MsgBoxName =  $Vorname + " " + $Nachname
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
        $OU = "ou=$Abteilung,dc=$DomSub,dc=$DomTop"
        $OUname = $Abteilung
        $OUpath = "dc=$DomSub,dc=$DomTop"
        $LDAPou = "LDAP://ou=$Abteilung,$OUpath"
    #GROUP
        $GrpSec = "$OUname-Mgmt"
        $GrpMail = "$OUname-Mail"
    #LAUFWERK PFAD
        $SMBpath = "E:\$Abteilung\"


#-----> OU abfragen - Wenn existiert weiter, sonst erstellen <-----#
      
        $ou_exists = [adsi]::Exists($LDAPou)
        if (-not $ou_exists){
                        New-ADOrganizationalUnit -Name $Abteilung -Path $OUpath -ProtectedFromAccidentalDeletion $true
                        New-ADGroup $GrpSec -path $OU -GroupCategory Security -GroupScope Global
                        New-ADGroup $GrpMail -Path $OU -GroupCategory Distribution -GroupScope Universal
        }

#-----> User übertragen - Wenn existiert MessageBox, sonst erstellen <-----#

        if (dsquery user -name $DisplayName){
                    [System.Windows.Forms.MessageBox]::Show("Benutzer '$MsgBoxName' bereits vorhanden!","AddUser",0,[System.Windows.Forms.MessageBoxIcon]::Exclamation)
                }
        else {                    New-ADUser `                        -name $DisplayName `                        -givenname $Nachname `                        -Surname $Vorname `                        -DisplayName $DisplayName `                        -Path $OU `                        -UserPrincipalName ($UserLogin + "@" + $DomName) `                        -SamAccountName $UserLogin `                        -AccountPassword $Passwort `                        -ChangePasswordAtLogon:$True `                        -Enabled $true
                    #Ordner erstellen & freigeben
                        New-Item -Path ($SMBpath + $UserLogin) -ItemType "Directory"
                        New-SmbShare -name $UserLogin -Path ($SMBpath + $UserLogin) -FullAccess $UserLogin, ($DomSub + "\" + $DomAdminEn)
                    #Sicherheitsgruppe zuweisen
                        Add-ADGroupMember $GrpSec -Members $UserLogin
                        Add-ADGroupMember $GrpMail -Members $UserLogin
                        break
        }
} while ($true)




