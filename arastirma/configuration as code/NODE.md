# NODE 

Aşağıdaki ekran görüntüsünde bir NODE ve ona bağlanmak için CREDENTIAL tanımı mevcut. Bu NODE'un etiketi de Jenkins->labelAtoms içinde tanımlı:

![image](https://user-images.githubusercontent.com/261946/192587533-8dac81a8-97a7-4292-a568-91ee64e6d8ca.png)

```yaml
credentials:
  system:
    domainCredentials:
    - credentials:
      - usernamePassword:
          id: "3953b6aa-ed6e-47f1-821e-51445c16d2df"
          password: "{AQAAABAAAAAQLh59MW0bzwx4qyOagxNz1h7r2qiqgYp4RCxs+XBAfF8=}"
          scope: GLOBAL
          username: "jenkins"
          usernameSecret: true

jenkins:
  labelAtoms:
  - name: "CINAR_BUILD_NODE_ULAK"
  - name: "built-in"
  nodes:
  - permanent:
      labelString: "CINAR_BUILD_NODE_ULAK"
      launcher:
        ssh:
          credentialsId: "3953b6aa-ed6e-47f1-821e-51445c16d2df"
          host: "192.168.13.179"
          port: 22
          retryWaitTime: 10
          sshHostKeyVerificationStrategy: "nonVerifyingKeyVerificationStrategy"
      mode: EXCLUSIVE
      name: "CINAR_BUILD_NODE_ULAK"
      nodeDescription: "CINAR_BUILD_NODE_ULAK"
      numExecutors: 2
      remoteFS: "/home/jenkins/workspace"
      retentionStrategy: "always"
```
