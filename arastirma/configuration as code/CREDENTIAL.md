# Credential

Aşağıdaki örnekte iki türlü kullanıcı tanımı görülebilir:
1. Kullanıcı adı ve şifresiyle (usernamePassword)
2. SSH Anahtarıyla (basicSSHUserPrivateKey)

![image](https://user-images.githubusercontent.com/261946/192586529-3d010b30-dc9b-4166-819a-dd1cfd7940c1.png)


```yaml
credentials:
  system:
    domainCredentials:
    - credentials:
      - usernamePassword:
          id: "3953b6aa-ed6e-47f1-821e-51445c16d2df"
          password: "{AQAAABAAAAAQLh59MW0bzwx4qyOagxNz1h7....=}"
          scope: GLOBAL
          username: "jenkins"
          usernameSecret: true
      - basicSSHUserPrivateKey:
          id: "34b41445-84b6-42ea-abc1-e74e88019643"
          privateKeySource:
            directEntry:
              privateKey: "{AQAAABAAAAaQJBEr52KwRajjec4wi2WtQa6j8pqAtINRMY....==}"
          scope: GLOBAL
          username: "jenkins.servis.pk"
          usernameSecret: true
```
