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
