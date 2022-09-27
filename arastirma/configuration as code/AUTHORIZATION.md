# Yetkisiz & Kullanıcı Girişi Olmaksızın

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

# LDAP ile Kullanıcı Girişi & Yetkilendirme

LDAP sunucu ve ayarlarını yaptıktan sonra config.xml dosyasında cem.topkaya kullanıcısını administrator olarak yetkilendiriyoruz:

```xml
<?xml version='1.1' encoding='UTF-8'?>
<hudson>
  <useSecurity>true</useSecurity>
  <authorizationStrategy class="hudson.security.GlobalMatrixAuthorizationStrategy">
    <permission>USER:hudson.model.Hudson.Administer:cem.topkaya</permission>
  </authorizationStrategy>
  <securityRealm class="hudson.security.LDAPSecurityRealm" plugin="ldap@2.12">
    <disableMailAddressResolver>false</disableMailAddressResolver>
    <configurations>
      <jenkins.security.plugins.ldap.LDAPConfiguration>
        <server>192.168.10.12</server>
        <rootDN>cn=Users,dc=ulakhaberlesme,dc=com,dc=tr</rootDN>
        <inhibitInferRootDN>false</inhibitInferRootDN>
        <userSearchBase></userSearchBase>
        <userSearch>sAMAccountName={0}</userSearch>
        <groupMembershipStrategy class="jenkins.security.plugins.ldap.FromGroupSearchLDAPGroupMembershipStrategy">
          <filter></filter>
        </groupMembershipStrategy>
        <managerDN>cn=redmine server,cn=Users,dc=ulakhaberlesme,dc=com,dc=tr</managerDN>
        <managerPasswordSecret>{AQAAABAAAAAQFJaAPQ5wSag3OXdRr0k4FkTAZbG4bABKg0t9AXDCLYY=}</managerPasswordSecret>
        <displayNameAttributeName>displayname</displayNameAttributeName>
        <mailAddressAttributeName>mail</mailAddressAttributeName>
        <ignoreIfUnavailable>false</ignoreIfUnavailable>
      </jenkins.security.plugins.ldap.LDAPConfiguration>
    </configurations>
    <userIdStrategy class="jenkins.model.IdStrategy$CaseInsensitive"/>
    <groupIdStrategy class="jenkins.model.IdStrategy$CaseInsensitive"/>
    <disableRolePrefixing>true</disableRolePrefixing>
  </securityRealm>
```

casc.yaml Dosyasındaki hali:

```yaml
jenkins:
  authorizationStrategy:
    globalMatrix:
      permissions:
      - "USER:Overall/Administer:cem.topkaya"
  securityRealm:
    ldap:
      configurations:
      - inhibitInferRootDN: false
        managerDN: "cn=redmine server,cn=Users,dc=ulakhaberlesme,dc=com,dc=tr"
        managerPasswordSecret: "{AQAAABAAAAAQFJaAPQ5wSag3OXdRr0k4FkTAZbG4bABKg0t9AXDCLYY=}"
        rootDN: "cn=Users,dc=ulakhaberlesme,dc=com,dc=tr"
        server: "192.168.10.12"
        userSearch: "sAMAccountName={0}"
      disableMailAddressResolver: false
      disableRolePrefixing: true
      groupIdStrategy: "caseInsensitive"
      userIdStrategy: "caseInsensitive"
```
