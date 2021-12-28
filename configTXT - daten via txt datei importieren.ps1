$var = get-content "e:\settings.txt"

$DomTOP = $var[1]
$DomSUB = $var[3]

$DomUser = $var[5]
$DomUserPw = $var[7]

$Subnet = $var[9]
$Netmask = $var[11]

$IPgateway = $var[13]

$NameDC = $var[15]
$IPdc = $var[17]

$NameCore = $var[19]
$IPcore = $var[21]

$DNSserver = $IPdc