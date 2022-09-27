# config.xml Yetkilendirme

Öncelikle config.xml dosyasını sildiğimizde Jenkins'i yeniden başlattığımız vakit kendi config.xml dosyasını yaratır ve sisteme login olmaksızın açılır.
Ama var olan config.xml'i yetkilendirme ve kullanıcı girişi olmaksızın başlatmak için aşağıdaki etiketleri kullanaibliriz.

```xml
<?xml version='1.1' encoding='UTF-8'?>
<hudson>
  <useSecurity>true</useSecurity>
  <authorizationStrategy class="hudson.security.AuthorizationStrategy$Unsecured"/>
  <securityRealm class="hudson.security.HudsonPrivateSecurityRealm">
    <disableSignup>true</disableSignup>
    <enableCaptcha>false</enableCaptcha>
  </securityRealm>
```

casc.yaml Dosyasını otomatik olarak yüklemek de mümkün.
Yukarıdaki config.xml'in casc.yaml dosyasına yansıması ise şöyledir:

```yaml
jenkins:
  disableRememberMe: false
  securityRealm:
    local:
      allowsSignup: false
      enableCaptcha: false
      users:
      - id: "admin"
        name: "admin"
        properties:
        - "apiToken"
        - favoriting:
            autofavoriteEnabled: true
        - "mailer"
        - "favorite"
        - "myView"
        - preferredProvider:
            providerId: "default"
        - "timezone"
```
