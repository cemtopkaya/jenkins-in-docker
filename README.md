# jenkins-in-docker
Hem master hem agent olacak şekilde docker içinde jenkins çalıştırır

Yansı oluşturmak için:
```
docker build --add-host security.ubuntu.com:91.189.91.39 -t cemt/jenkins-master -f .\jenkins-master.dockerfile .

docker build --add-host security.ubuntu.com:91.189.91.39 -t cemt/jenkins-agent -f .\jenkins-agent.dockerfile .
```

Konteyner yaratmak için:
```
docker run -d --rm -p 8084:8084 -e JENKINS_OPTS=--httpPort=8084 --name jenkmaster -e DOCKER_HOST=tcp://host.docker.internal:2375 cemt/jenkins-master

docker run -d --rm -p 50000:50000 --name jenkagent -e DOCKER_HOST=tcp://host.docker.internal:2375 cemt/jenkins-agent
```
