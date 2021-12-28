
#smb freigaben löschen

$csvFile = "c:\user.csv"
$users = Import-CSV $csvfile

foreach ($i in $users) {
                $UserLogin = $i.LastName + "." + $i.FirstName
                $DisplayName = $i.FirstName + "." + $i.LastName
                $SecurePass = ConvertTo-SecureString $i.DefaultPassword -AsPlainText -Force
                
                Remove-SmbShare -name $UserLogin -force
}