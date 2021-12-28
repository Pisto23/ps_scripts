    #USER
        $csvFile = "E:\configCSV.csv"
        $csvIMP = Import-CSV $csvfile
    #DOMAINADMIN
        $DomAdminEn = "Domain Admins"
        $DomAdminDe = "Domänen-Admins"
    #OGANIZATIONAL UNIT
        $OUpath = "dc=$DomSub,dc=$DomTop"
        $DomainSub = $csvIMP.SubDom
        $DomainTop = $csvIMP.TopDom
        $Domain = $DomainSub + "." + $DomainTop
        $DomUser = $csvIMP.User
        $DomPW = $csvIMP.Password | ConvertTo-SecureString -AsPlainText -Force
        $IPgateway = $csvIMP.IPgateway
        $IPdc = $csvIMP.IPdc
        $IPsrv1 = $csvIMP.IPsrv1
        

