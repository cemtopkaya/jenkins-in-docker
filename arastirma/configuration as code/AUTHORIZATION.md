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

## Sadece USERS İçinde

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

## Gruplarda Arama

Grup yetkilendirmesi:
```xml
    <permission>GROUP:hudson.model.Hudson.Read:Cekirdek_Sebeke_Yazilimlari_Mudurlugu</permission>
```

```xml
<?xml version='1.1' encoding='UTF-8'?>
<hudson>
  <useSecurity>true</useSecurity>
  
  <securityRealm class="hudson.security.LDAPSecurityRealm" plugin="ldap@2.12">
    <disableMailAddressResolver>false</disableMailAddressResolver>
    <configurations>
      <jenkins.security.plugins.ldap.LDAPConfiguration>
        <server>192.168.10.12</server>
        <rootDN>cn=Users,dc=ulakhaberlesme,dc=com,dc=tr</rootDN>
        <inhibitInferRootDN>false</inhibitInferRootDN>
        <userSearchBase></userSearchBase>
        <userSearch>sAMAccountName={0}</userSearch>
        <groupSearchFilter>(&amp; (cn={0}) (objectclass=group) )</groupSearchFilter>
        <groupMembershipStrategy class="jenkins.security.plugins.ldap.FromUserRecordLDAPGroupMembershipStrategy">
          <attributeName>memberOf</attributeName>
        </groupMembershipStrategy>
        <managerDN>cn=redmine server,cn=Users,dc=ulakhaberlesme,dc=com,dc=tr</managerDN>
        <managerPasswordSecret>{AQAAABAAAAAQoDmaJ/yCJfMCPN4whjn443RmqFYwVQEahMe5omjwCTU=}</managerPasswordSecret>
        <displayNameAttributeName>displayname</displayNameAttributeName>
        <mailAddressAttributeName>mail</mailAddressAttributeName>
        <ignoreIfUnavailable>false</ignoreIfUnavailable>
      </jenkins.security.plugins.ldap.LDAPConfiguration>
    </configurations>
    <userIdStrategy class="jenkins.model.IdStrategy$CaseInsensitive"/>
    <groupIdStrategy class="jenkins.model.IdStrategy$CaseInsensitive"/>
    <disableRolePrefixing>true</disableRolePrefixing>
  </securityRealm>

  <authorizationStrategy class="hudson.security.GlobalMatrixAuthorizationStrategy">
    <permission>GROUP:hudson.model.Hudson.Administer:Cekirdek_Sebeke_Yazilimlari_Mudurlugu</permission>
    <permission>USER:hudson.model.Hudson.Administer:alp.eren</permission>
    <permission>USER:hudson.model.Hudson.Administer:redmine.server</permission>
  </authorizationStrategy>

```

Neden grup aramasında `cn={0}` yazdığımızı görmek için bir LDAP araması yapalım ve grup adının `CN=...` olduğunu görelim.
Distinguised Name kısmında nasıl bir süzgeç kullanacağımızı görebiliriz: `CN=Cekirdek_Sebeke_Yazilimlari_Mudurlugu,CN=Users,DC=ulakhaberlesme,DC=com`

```shell
$ ldapsearch -h 192.168.10.12 -p 389 -D "redmine.server@ulakhaberlesme.com.tr" -W -b "cn=Cekirdek_Sebeke_Yazilimlari_Mudurlugu,cn=Users,dc=ulakhaberlesme,dc=com,dc=tr"
Enter LDAP Password:
# extended LDIF
#
# LDAPv3
# base <cn=Cekirdek_Sebeke_Yazilimlari_Mudurlugu,cn=Users,dc=ulakhaberlesme,dc=com,dc=tr> with scope subtree
# filter: (objectclass=*)
# requesting: ALL
#

# Cekirdek_Sebeke_Yazilimlari_Mudurlugu, Users, ulakhaberlesme.com.tr
dn: CN=Cekirdek_Sebeke_Yazilimlari_Mudurlugu,CN=Users,DC=ulakhaberlesme,DC=com
 ,DC=tr
objectClass: top
objectClass: group
cn: Cekirdek_Sebeke_Yazilimlari_Mudurlugu
description: Ldif Yapisi
member: CN=Hakan BATMAZ,CN=Users,DC=ulakhaberlesme,DC=com,DC=tr
member: CN=Serkan ACAR,CN=Users,DC=ulakhaberlesme,DC=com,DC=tr
member: CN=Ugur Alp TURE,CN=Users,DC=ulakhaberlesme,DC=com,DC=tr
member: CN=Fatih DARTICI,CN=Users,DC=ulakhaberlesme,DC=com,DC=tr
member:: Q049QXLEsW5jIEFscCBFUkVOLENOPVVzZXJzLERDPXVsYWtoYWJlcmxlc21lLERDPWNvb
 SxEQz10cg==
member: CN=Tolga Hakan Oduncu,OU=Disabled,DC=ulakhaberlesme,DC=com,DC=tr
member:: Q049TWVobWV0IEVtaW4gQkHFnkFSLENOPVVzZXJzLERDPXVsYWtoYWJlcmxlc21lLERDP
 WNvbSxEQz10cg==
member: CN=Sami GURPINAR,CN=Users,DC=ulakhaberlesme,DC=com,DC=tr
member: CN=Cem Topkaya,CN=Users,DC=ulakhaberlesme,DC=com,DC=tr
member: CN=Yasin Caner,CN=Users,DC=ulakhaberlesme,DC=com,DC=tr
member:: Q049w5ZtZXIgWmVrdmFuIFnEsWxtYXosQ049VXNlcnMsREM9dWxha2hhYmVybGVzbWUsR
 EM9Y29tLERDPXRy
member:: Q049QsO8bGVudCBLYW1iZXJvxJ9sdSxDTj1Vc2VycyxEQz11bGFraGFiZXJsZXNtZSxEQ
 z1jb20sREM9dHI=
member: CN=Ozlem Aydin,CN=Users,DC=ulakhaberlesme,DC=com,DC=tr
member: CN=Omer Faruk Aktulum,OU=Disabled,DC=ulakhaberlesme,DC=com,DC=tr
distinguishedName: CN=Cekirdek_Sebeke_Yazilimlari_Mudurlugu,CN=Users,DC=ulakha
 berlesme,DC=com,DC=tr
instanceType: 4
whenCreated: 20220729142947.0Z
whenChanged: 20220805122659.0Z
uSNCreated: 54524713
uSNChanged: 54825063
name: Cekirdek_Sebeke_Yazilimlari_Mudurlugu
objectGUID:: clXWE3y/JkucIoowMQIGLA==
objectSid:: AQUAAAAAAAUVAAAA0zVP2bd+qwQ+r7HmbBEAAA==
sAMAccountName: Cekirdek_Sebeke_Yazilimlari_Mudurlugu
sAMAccountType: 268435456
groupType: -2147483646
objectCategory: CN=Group,CN=Schema,CN=Configuration,DC=ulakhaberlesme,DC=com,D
 C=tr
dSCorePropagationData: 16010101000000.0Z

# search result
search: 2
result: 0 Success

# numResponses: 2
# numEntries: 1
```

casc.yaml Dosyasında ise:

```yaml
jenkins:
  agentProtocols:
  - "JNLP4-connect"
  - "Ping"
  authorizationStrategy:
    globalMatrix:
      permissions:
      - "GROUP:Overall/Administer:Cekirdek_Sebeke_Yazilimlari_Mudurlugu"
      - "USER:Overall/Administer:alp.eren"
      - "USER:Overall/Administer:redmine.server"
  securityRealm:
    ldap:
      configurations:
      - groupMembershipStrategy:
          fromUserRecord:
            attributeName: "memberOf"
        groupSearchFilter: "(& (cn={0}) (objectclass=group) )"
        inhibitInferRootDN: false
        managerDN: "cn=redmine server,cn=Users,dc=ulakhaberlesme,dc=com,dc=tr"
        managerPasswordSecret: "{AQAAABAAAAAQoDmaJ/yCJfMCPN4whjn443RmqFYwVQEahMe5omjwCTU=}"
        rootDN: "cn=Users,dc=ulakhaberlesme,dc=com,dc=tr"
        server: "192.168.10.12"
        userSearch: "sAMAccountName={0}"
      disableMailAddressResolver: false
      disableRolePrefixing: true
      groupIdStrategy: "caseInsensitive"
      userIdStrategy: "caseInsensitive"
  slaveAgentPort: 0
```

![image](https://user-images.githubusercontent.com/261946/192666106-73f5a55d-344f-4339-a8e4-8edd33e744e5.png)

