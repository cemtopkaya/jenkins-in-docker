
### LDAP Sunucu Bilgilerini Girmek 

Aşağıdaki ekran çıktısında LDAP bilgileri girilmeden az önce tüm dosya tarihleri sabitleniyor ve LDAP bilgilerinden sonra değişen dosya dizinleri listeliyoruz:

![image](https://user-images.githubusercontent.com/261946/191525174-3d9f3054-204c-4f49-b41a-a3d347d91421.png)


### LDAP Kullanıcı Tanımlama ve Yetkilendirme Stratejisini Değiştirmek

LDAP ile kullanıcı girişi için **Configuration as Code** ayarı aşağıdaki gibi oluşturulabilir:

```yaml
jenkins:
  securityRealm:
    ldap:
      configurations:
      - inhibitInferRootDN: false
        managerDN: "cn=redmine server,cn=Users,dc=ulakhaberlesme,dc=com, dc=tr"
        managerPasswordSecret: "{AQAAABAAAAAQe+gQ3KYbPT+c1Ub7aubdCezd3GkTL4dCz/dvq6liQ1s=}"
        rootDN: "cn=Users,dc=ulakhaberlesme,dc=com,dc=tr"
        server: "192.168.10.12"
        userSearch: "sAMAccountName={0}"
```


LDAP üstünden kullanıcı tanımı Matrix temelli yetkilendirme ile oluşturulunca config.xml değişimi:

![image](https://user-images.githubusercontent.com/261946/191437094-0a2d4c2e-131b-4a0c-8e68-20cd09f6edbe.png)

Authorization strateji şundan:
```xml
<authorizationStrategy class="hudson.security.AuthorizationStrategy$Unsecured"/>
```

Buna değişiyor:

```xml
<authorizationStrategy class="hudson.security.GlobalMatrixAuthorizationStrategy">	
    <permission>USER:hudson.model.Hudson.Administer:cem.topkaya</permission>	
</authorizationStrategy>
```

Dosyaların tarihlerinde değişime göre etkilenenler:

![image](https://user-images.githubusercontent.com/261946/191437497-24abf7a8-3af1-4711-8cf1-e4cfdf1c21c0.png)
