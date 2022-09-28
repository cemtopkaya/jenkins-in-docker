# LDAP Araçları

https://docs.cloudbees.com/docs/cloudbees-ci-kb/latest/troubleshooting-guides/cannot-make-my-ldap-configuration-to-work

## JExplorer

![image](https://user-images.githubusercontent.com/261946/192656825-82a24829-8840-4665-99fc-aaac5bc441fc.png)

![image](https://user-images.githubusercontent.com/261946/192656897-a1f9176b-3bc4-43f6-a597-397050252572.png)

## ldapsearch

Kuralım: https://askubuntu.com/questions/869618/how-to-install-ldapsearch-on-16-04

```shell
sudo apt install ldap-utils
```

Arama yapalım:

```shell
ldapsearch -LLL -H ldap://<IP_ADDRESS>:<PORT> -M -b "<searchbase>" -D "<binddn>" -w "<passwd>" "(uid=<userid>)"
```

- Gerekirse özel karakterden `\` (eğik çizgi) ile kaçmaya özen gösterin.
- ldapsearch'ü Jenkins'i çalıştırdığınız aynı sunucuya test için kurmanız gerekecek. 
- Linux için ldapsearch, ldap-utils paketine dahildir.
- Aşağıdaki komutlar için, şifrenizi maskelemek istemeniz durumunda, -w "<passwd>" ile değiştirilebilir.
- "-W" anahtarını kullandığınızda şifreyi sürekli soracaktır.
- "-y ./pass.txt", ile /pass.txt kimlik bilgilerinizi parametre olarak geçirir.

```shell
$ ldapsearch -LLL -H ldap://ldap.example.com:389 -M -D "ou=people,dc=example,dc=com" -b "dc=example,dc=com" -w "pass"`
```
  
### Örnek Sorgulama

```shell
$ ldapsearch -h 192.168.10.12 -p 389 -D "kullanici.adi@ulakhaberlesme.com.tr" -w sifre -b  "CN=Cekirdek_Sebeke_Yazilimlari_Mudurlugu,CN=Users,DC=ulakhaberlesme,DC=com,DC=tr"
# extended LDIF
#
# LDAPv3
# base <CN=Cekirdek_Sebeke_Yazilimlari_Mudurlugu,CN=Users,DC=ulakhaberlesme,DC=com,DC=tr> with scope subtree
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
member: CN=****,CN=Users,DC=ulakhaberlesme,DC=com,DC=tr
member: CN=***,CN=Users,DC=ulakhaberlesme,DC=com,DC=tr
member: CN=***,CN=Users,DC=ulakhaberlesme,DC=com,DC=tr
member: CN=***,CN=Users,DC=ulakhaberlesme,DC=com,DC=tr
member:: Q049***cg==
member: CN=***,OU=Disabled,DC=ulakhaberlesme,DC=com,DC=tr
member:: Q049T***cg==
member: CN=***,CN=Users,DC=ulakhaberlesme,DC=com,DC=tr
member: CN=Cem Topkaya,CN=Users,DC=ulakhaberlesme,DC=com,DC=tr
member: CN=***,CN=Users,DC=ulakhaberlesme,DC=com,DC=tr
member:: Q049w***XRy
member:: Q049Q***HI=
member: CN=***,CN=Users,DC=ulakhaberlesme,DC=com,DC=tr
member: CN=***,OU=Disabled,DC=ulakhaberlesme,DC=com,DC=tr
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
