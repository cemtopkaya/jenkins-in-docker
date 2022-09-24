# ---------------------------------------------------------------------------------------------------------------------------------------------------------#
#                               KOMUTLAR VE AÇIKLAMALARI                                                                                                   #
#                                                                                                                                                          #
# docker build --add-host security.ubuntu.com:91.189.91.39               `                                                                                 #
#              --build-arg user_id=$(id -u jenkins)                      `                                                                                 #
#              --build-arg user_group_id=$(id -g jenkins)                `                                                                                 #
#              --build-arg JENKINS_BUILDS_DIR=/builds                    `                                                                                 #
#              --build-arg YUKLENECEK_PLUGINS_DOSYASI=/tmp/plugins/cinar-plugins.txt `                `                                                     #                                                                                 #
#              --add-host bitbucket.ulakhaberlesme.com.tr:192.168.10.14  `                                                                                 #
#              -t cemo                                                   `                                                                                 #
#              -f .\jenkins-latest-jdk-11.dockerfile .                                                                                                     #
#                                                                                                                                                          #
#                                                                                                                                                          #
# docker run -it --rm                                                  `                                                                                   #
#            -p 8090:8090                                              `                                                                                   #
#            -e JENKINS_OPTS=--httpPort=8090                           `                                                                                   #
#            -e DOCKER_HOST=tcp://host.docker.internal:2375            `                                                                                   #
#            --dns 176.31.121.197                                      `                                                                                   #
#            --add-host archive.ubuntu.com:91.189.88.142               `                                                                                   #
#            --add-host security.ubuntu.com:91.189.88.142              `                                                                                   #
#            --add-host updates.jenkins.io:52.202.51.185               `                                                                                   #
#            --add-host get.jenkins.io:52.167.253.43                   `                                                                                   #
#            --add-host bitbucket.ulakhaberlesme.com.tr:192.168.10.14  `                                                                                   #
#            --name jendock                                            `                                                                                   #
#            cemo                                                                                                                                          #
# KAYNAKLAR:                                                                                                                                               #
# https://github.com/jenkinsci/docker#preinstalling-plugins                                                                                                #
# https://devopscube.com/docker-containers-as-build-slaves-jenkins/#Configure_a_Docker_Host_With_Remote_API_Important                                      #
# ---------------------------------------------------------------------------------------------------------------------------------------------------------#

FROM ubuntu:focal AS base
#-------------------------------------------------------------------------------------------------------------------------------------------------------------#
#                                                              KURULACAK PAKETLER ve AÇIKLAMALARI                                                             #
# apt-transport-https: APT transport for downloading via the HTTP Secure protocol (HTTPS)                                                                     #
# zip: jenkins.war içindeki eklentileri (detached-plugins) plugins dizinine açmak için                                                                        #
# gettext-base: This package includes the gettext and ngettext programs which allow other packages to internationalize the messages given by shell scripts.   #
# Jenkins içinde çeşitli araçlara ihtiyaç oluyor: sshd, jdk, git, node, python vs.                                                                            #
# openjdk-8-jdk: Install JDK 8 (latest stable edition at 2019-04-01)                                                                                          #
#-------------------------------------------------------------------------------------------------------------------------------------------------------------#

RUN apt-get update && \
    apt-get -qy full-upgrade && \
    apt-get install -qy apt-transport-https \
                      zip \
                      git \
                      curl \
                      gettext-base

RUN DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get -y install tzdata


#------------------------------------------------------------------------------------------------------------------------------------------------------------#
#                                           OPEN JDK KURULUMU                                                                                                #
#                                                                                                                                                            #
#------------------------------------------------------------------------------------------------------------------------------------------------------------#
RUN apt-get install -y software-properties-common && \
    add-apt-repository -y ppa:openjdk-r/ppa && \
    apt-get install -y openjdk-11-jdk


#------------------------------------------------------------------------------------------------------------------------------------------------------------#
#                                           DOCKER-CE-CLI KURULUMU                                                                                           #
# Docker paketlerinden istemci paketini kurup sunucu olarak başka bir docker host'u göstereceğiz. DOCKER_HOST konteynerin hostu olacak (window için)         #
# Docker dosyalarının indirileceğği paket havuzunun adresine erişimimizde GPG anahtarı kullanacağız. Bu anahtar sayesinde eriştiğimiz kaynağa güvenli        #
# sağlamış olacağız. Önce GPG anahtarını docker.com adresinden indiriyor, bu reponun adresini girdiğimiz kayıt içinde GPG adresinin varsayılan GPG dosyaları #
# ile aynı yerde olmaması sebebiyle signed-by özelliği ile belirteceğiz.                                                                                     #
#------------------------------------------------------------------------------------------------------------------------------------------------------------#
RUN curl --create-dirs -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu focal stable" > /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    apt-get install -y docker-ce-cli


# -----------------------------------------------------------------------------------------#
#                               JENKINS DOSYALARININ INDIRILMESI                           #
# Jenkins temel dosyalarının bu aşamada indirilmesi sağlanıyor. Kurulum ve ayarlar sonraki #
# aşamada ele alınacak.                                                                    #
#                                                                                          #
# /usr   : Tüm kullanıcılarca paylaşılan verileri içeren dizindir. [https://t.ly/ELoo]     #
# -----------------------------------------------------------------------------------------#
FROM base as jenkins-base
USER root

# curl ile https isteklerinde gelen sertifikaların doğrulanması gerekeceği için update-ca-certificates ile güncel sertifikalar indirilecek.
RUN update-ca-certificates

RUN curl --create-dirs -fL https://mirrors.jenkins-ci.org/war-stable/latest/jenkins.war -o /usr/share/jenkins/jenkins.war
# ADD http://mirrors.jenkins-ci.org/war-stable/latest/jenkins.war /usr/share/jenkins/jenkins.war
# COPY ./bin/jenkins-2.303.2.war /usr/share/jenkins/jenkins.war

RUN curl --create-dirs -fL https://github.com/jenkinsci/plugin-installation-manager-tool/releases/download/2.12.8/jenkins-plugin-manager-2.12.8.jar -o /opt/jenkins-plugin-manager-2.12.8.jar
# ADD https://github.com/jenkinsci/plugin-installation-manager-tool/releases/download/2.12.8/jenkins-plugin-manager-2.12.8.jar /opt/jenkins-plugin-manager-2.12.8.jar
# COPY ./bin/jenkins-plugin-manager-2.12.8.jar ./jenkins-plugins/plugins.yaml /opt/







# ----------------------------------------------------------------------------------------------------------------------------------------------------------#
#                               JENKINS KURULUM SİHİRBAZI                                                                                                   #
# Jenkins tanımları ve ayarları için bu stage kullanılacaktır.                                                                                              #
# ----------------------------------------------------------------------------------------------------------------------------------------------------------#
FROM jenkins-base

# ----------------------------------------------------------------------------------------------------------------------------------------------------------#
#                               JENKINS KURULUM SİHİRBAZI                                                                                                   #
# Jenkins master varsayılan olarak kurulum ile başlatılır. Kurulum yapmadan çalışması için jenkins.install.runSetupWizard=false  işaretlenir.               #
# Genelde /home/jenkins kullanıcı dizini içine dosya yetkilerinde kolaylık olsun diye kurulum yapılır ancak dizin yapısı yönetilemez hal alır.              #
# Bu yüzden Jenkins dizini /usr/share/jenkins olarak kalacak ve jenkins isimli kullanıcı dizini .ssh gibi dizinleri, olması gerektiği gibi içerecek.        #
#                                                                                                                                                           #
# Diğer dizinleri konteynerin haricinden erişilebilir olması için VOLUME ile dış erişime açacağız.                                                          #
#   JENKINS_HOME       = /usr/share/jenkins                                                                                                                 #
#   JENKINS_JOBS_DIR   = ${JENKINS_HOME}/jobs                                                                                                               #
#   JENKINS_SECRETS_DIR= ${JENKINS_HOME}/secrets                                                                                                            #
#   JENKINS_NODES_DIR  = ${JENKINS_HOME}/nodes                                                                                                              #
#   JENKINS_USERS_DIR  = ${JENKINS_HOME}/users                                                                                                              #
#   PLUGIN_DIR         = ${JENKINS_HOME}/plugins                                                                                                            #
#   PLUGINS_YAML       = ${JENKINS_HOME}/plugins.yaml                                                                                                       #
#                                                                                                                                                           #
# Eğer varolan bir JENKINS agent bu konteyner üzerine taşınacaksa dosya ve dizinlerin (plugins, jobs, users, secrets, nodes, secret.key, config.xml vs)     #
# bu konteyner içinde tanımlı kullanıcı (u:jenkins uid:1000 g:jenkins gid:1000) ile yetkilendirilmeleri host makinada yapılmış olmalı.                      #
#   Örn. chown -R jenkins:jenkins ./plugins                                                                                                                 #
#                                                                                                                                                           #
# ----------------------------------------------------------------------------------------------------------------------------------------------------------#

# Jenkins dosyaları JENKINS_HOME ortam değişkeninin gösterdiği dizinde olacak
ENV JENKINS_HOME /usr/share/jenkins

# Konteyner çalıştığında user_name argumanındaki kullanıcı ile çalıştırılacak ve JENKINS bu kullanıcı altında işlerini yapacak
ARG user_id=1000
ARG user_name=jenkins
ARG user_password=jenkins
ENV JENKINS_USER_HOME_DIR "/home/${user_name}"

# Konteynerin kullanıcısı user_group_name ile tanımlı gruba üye olacak
ARG user_group_id=1000
ARG user_group_name=jenkins

# Konteynerin root kullanıcısının şifresi
ENV ROOT_USER_PASSWORD sifre123
ARG root_password=${ROOT_USER_PASSWORD}

#-------------------------------------------------------------------------------------------------------------------------------------------------------------#
#                                                              KULLANICI-GRUP AYARLARI                                                                        #
# jenkins adında bir kullanıcıyı jenkins adında bir grup içinde oluşturacağız.                                                                                #
# Eğer bşka bir JENKINS sunucusundaki bilgileri (jobs, nodes, users, secrets, credentials.xml vs.) bu yansının örneği olacak bir konteynere bağlayacaksak,    #
# aktarılacak dosya ve dizinlerin sahipliğindeki kullanıcının id ve ait olduğu grubun id değerlerini yansıyı derlerken arguman olarak vermemiz gerekiyor.     #
#                                                                                                                                                             #
# Buna göre aşağıdaki derleme komutuyla host bilgisayardaki kullanıcının ID ve GRUP_ID değerleriyle imaj içinde bir kullanıcı oluşturuyoruz:                  #
#     docker build --build-arg user_id=$(id -u $USER) --build-arg user_group_id=$(id -g $USER) -t cemkins -f jenkins-latest-jdk-11.dockerfile .               #
#                                                                                                                                                             #
# Eğer sudo paketi kuruluysa jenkins kullanıcısını sudoers grubuna şifre istemeden super user olarak işlemleri yapacak şekilde ekleyeceğiz.                   #
# jenkins kullanıcısının ev dizini jenkins uyglamasının çalışacağı yer olacak.                                                                                #
# Hem jenkins hem root kullanıcısının şifrelerini SSH bağlantılarını yapabilmek için tayin edeceğiz.                                                          #
#-------------------------------------------------------------------------------------------------------------------------------------------------------------#
# jenkins Adında bir grup oluşturup
RUN groupadd -g ${user_group_id} ${user_group_name}
# jenkins adında  bir kullanıcıyı bu gruba ekliyoruz
RUN useradd -c "Jenkins kullanici aciklamasi" -d "$JENKINS_USER_HOME_DIR" -u ${user_id} -g ${user_group_id} -m ${user_name} -s /bin/bash
RUN echo "${user_name}:${user_password}" | chpasswd
# jenkins kullanıcısını sudoers grubuna her işlemi bir daha şifre sormadan yapabilsin diye ekliyoruz
# RUN echo "${user_name}  ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers.d/${user_name} && chmod 0440 /etc/sudoers.d/${user_name}
# Bu konteynere root kullanıcısını kullanarak SSH protokolüyle bağlanmak istediğimizde şifreyi sshpass ile geçirebilmek için ayarlayalım
RUN echo 'root:${root_password}' | chpasswd


#-------------------------------------------------------------------------------------------------------------------------------------------------------------#
#                                                              SSH SERVER                                                                                     #
# SSH veya Secure Shell, iki bilgisayarın iletişim kurmasını (c.f http veya web sayfaları gibi köprü metni aktarmak için kullanılan protokol olan köprü metni #
# aktarım protokolü) ve verileri paylaşmasını sağlayan bir ağ iletişim protokolüdür.                                                                          #
# Root kullanıcısıyla SSH yapılabilmeli ve bunu şifre yoluyla sağlayabilmeli. Aksi halde root kullanıcısı giriş yapamaz ve/veya açık-gizli anahtar gerekir    #
# Eğer SSH bir hizmet olarak çalışacaksa ya "systemctl enable ssh" olmalı ve konteynerin bir sonraki açılışında başlatılır veya hemen çalıştırılır.           #
#-------------------------------------------------------------------------------------------------------------------------------------------------------------#
RUN apt-get install -qy openssh-server && \
    sed -i 's|session    required     pam_loginuid.so|session    optional     pam_loginuid.so|g' /etc/pam.d/sshd && \
    sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    # SSH sunucusu çalışsın diye /var/run/sshd dizinini yaratıyoruz
    mkdir -p /var/run/sshd && \
# RUN service ssh restart
    # Bu konteynere jenkins kullanıcısını kullanarak SSH ile bağlanmak istersek iki türlü kullanıcı doğrulaması yapılır:
    # 1. jenkins Kullanıcı adı ve şifresiyle ($ sshpass -p 'jenkins-sifresi' ssh -o StrictHostKeyChecking=no jenkins@konteyner_ip)
    # 2. jenkins Kullanıcısının ev dizinin altındaki .ssh dizininde olan açık-gizli anahtar ikilisiyle
    mkdir -p ${JENKINS_USER_HOME_DIR}/.ssh && \
    chown -R ${user_name} ${JENKINS_USER_HOME_DIR}/.ssh && \
    chmod 700 ${JENKINS_USER_HOME_DIR}/.ssh && \
    cd ${JENKINS_USER_HOME_DIR}/.ssh && \
    # jenkins Kullanıcısı için açık-gizli anahtarı (gizli anahtarı şifresiz olarak) oluşturuyoruz
    ssh-keygen -q -t rsa -N '' -f ${JENKINS_USER_HOME_DIR}/.ssh/id_rsa && \
    # jenkins Kullanıcısıyla SSH yapılırken açık anahtar ile doğrulama yapılırsa "yetki verilen anahtarlar" dosyasına açık anahtarı ekliyoruz
    # Elbette bu açık anahtarın istemciye eklenmesi ve /home/istemcideki_baglanti_yapacak_kullanicinin/.ssh/config dosyasında ayarların yapılması gerekiyor
    # Bkz. https://github.com/cemtopkaya/dockerfile_jenkinsfile/blob/main/Dockerfile
    cat ${JENKINS_USER_HOME_DIR}/.ssh/id_rsa.pub > ${JENKINS_USER_HOME_DIR}/.ssh/authorized_keys


#-------------------------------------------------------------------------------------------------------------------------------------------------------------#
#                                                            SERTİFİKA AYARLARI                                                                               #
# Sunucudaki sertifikalar güncellenir ve /etc/ssl/certs dizini jenkins kullanıcısına sahiplendirilir                                                          #
# ulakhaberlesme'nin sertifikasını indirip update-ca-certificates ile faal sertifikalar listesini güncelleyeceğiz                                             #
# bitbucket.ulakhaberlesme.com.tr adresine derleme sırasında erişebilmek için "--add-host domainname:ip" 'anahtarı docker build komutuna verilmeli            #
#                                                                                                                                                             #
#-------------------------------------------------------------------------------------------------------------------------------------------------------------#
USER root


# COPY ./volume/certs/ulakhaberlesme.crt /etc/ssl/certs/ulakhaberlesme.crt
RUN echo -n | openssl s_client -showcerts -connect bitbucket.ulakhaberlesme.com.tr:8443 \
            2>/dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > /etc/ssl/certs/ulakhaberlesme.crt

RUN chown -R ${user_name}:${user_group_name} /etc/ssl/certs/
RUN chown -R ${user_name}:${user_group_name} /etc/default/cacerts
RUN chown -R ${user_name}:${user_group_name} /usr/local/share/ca-certificates/
RUN update-ca-certificates -f

#-------------------------------------------------------------------------------------------------------------------------------------------------------------#
#                                                              MAVEN KURULUMU & AYARLARI                                                                      #
#-------------------------------------------------------------------------------------------------------------------------------------------------------------#
# Install maven
# RUN apt-get install -qy maven && \
#ADD settings.xml /home/jenkins/.m2/


#------------------------------------------------------------------------------------------------------------------------------------------------------------#
#                                           JENKINS KURULUMU                                                                                                 #
# jenkins.war uygulaması Jenkins olarak çalışacak ancak eklentiler, ayar dosyaları gibi ek ayarlara ihtiyacımız olack.                                       #
#                                                                                                                                                            #
#  https://www.jenkins.io/doc/book/managing/system-properties/#jenkins-model-jenkins-buildsdir                                                               #
#  -Djenkins.model.Jenkins.buildsDir=${JENKINS_HOME}/builds/${ITEM_FULL_NAME}                                                                                #
#  -Djenkins.model.Jenkins.workspacesDir=${JENKINS_HOMW}/workspace/${ITEM_FULL_NAME}                                                                         #
#------------------------------------------------------------------------------------------------------------------------------------------------------------#
ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false -Dpermissive-script-security.enabled=true -Djava.awt.headless=true

# ENV JENKINS_OPTS --httpPort=-1 --httpsPort=8083 --httpsCertificate=/var/lib/jenkins/cert --httpsPrivateKey=/var/lib/jenkins/pk
ENV JENKINS_OPTS --httpPort=8090 --argumentsRealm.roles.user=yonetici --argumentsRealm.passwd.yonetici=sifre --argumentsRealm.roles.yonetici=admin
ENV JENKINS_SLAVE_AGENT_PORT=50000

ENV JENKINS_UC=https://updates.jenkins-ci.org
ENV JENKINS_UC_DOWNLOAD=${JENKINS_UC}/download
ENV JENKINS_UC_EXPERIMENTAL=https://updates.jenkins.io/experimental
ENV JENKINS_INCREMENTALS_REPO_MIRROR=https://repo.jenkins-ci.org/incrementals

ENV COPY_REFERENCE_FILE_LOG=/var/log/copy_reference_file.log
# referans dosyalarını yalnızca bir kez kopyaladığımızdan emin olmak için bayrak olarak kullanılan işaret dosyası
ENV COPY_REFERENCE_MARKER=${JENKINS_HOME}/.docker-onrun-complete

# docker host sunucusu olarak kendi hostunu gösteriyoruz ancak değiştirilebilir.
ENV DOCKER_HOST=tcp://host.docker.internal:2375

# `/usr/share/jenkins/ref/` yeni bir kurulumda ayarlamak istediğimiz tüm referans yapılandırmalarını içerir.
# Özel jenkins Docker yansınızda yer alacak diğer eklentiler veya ayar dosyasıları için bu dizini kullanın.
RUN mkdir -p /usr/share/jenkins/ref/init.groovy.d
RUN echo '\
import hudson.model.*;\n\
import jenkins.model.*;\n\
\n\
Thread.start {\n\
      sleep 10000\n\
      println "--> setting agent port for jnlp"\n\
      Jenkins.instance.setSlaveAgentPort(50000)\n\
}' > /usr/share/jenkins/ref/init.groovy.d/init.groovy



#-------------------------------------------------------------------------------------------------------------------------------------------------------------#
#                                                            EKLENTİ  AYARLARI                                                                                #
#                                                                                                                                                             #
# Eklentileri tüm ayrıntılarıyla xml formatında görmek için:                                                                                                  #
# -----> http://<jenkins-url>/pluginManager/api/xml?depth=1                                                                                                   #
# -----> http://<jenkins-url>/pluginManager/api/xml?depth=1&xpath=/*/*/shortName|/*/*/version&wrapper=plugins                                                 #
#                                                                                                                                                             #
# Eklentileri önceleri install-plugins.sh adında bir betikle yapıyorken sonradan jenkins-plugin-manager.jar dosyasıyla yapar olmuşlar.                        #
# Bu yüzden jenkins-plugin-manager.jar dosyası indirilir veya kopyalanır. Betik dosyasına geçirilen parametreler jar'a geçirilir                              #
#                                                                                                                                                             #
# Veya eklenti dosyaları, docker yansısı derlenirken kopyalanır.                                                                                              #
#                                                                                                                                                             #
# Sistemde yüklü eklentileri ve sürüm bilgilerini öğrenmek için aşağıdaki betiği http://localhost:8090/script adresinde çalıştırabilirsiniz:                  #
#   Jenkins.instance.pluginManager.plugins.each{                                                                                                              #
#     plugin ->                                                                                                                                               #
#       println ("${plugin.getDisplayName()} (${plugin.getShortName()}): ${plugin.getVersion()}")                                                             #
#   }                                                                                                                                                         #
#                                                                                                                                                             #
# Sistemde yüklü eklentileri birinci seviyede bağımlılıklarıyla görebilmek için aşağıdaki betiği localhost:8090/script adresinde çalıştırabilirsiniz:         #
#   def plugins = jenkins.model.Jenkins.instance.getPluginManager().getPlugins()                                                                              #
#   println "digraph test {"                                                                                                                                  #
#   plugins.each {                                                                                                                                            #
#       def plugin = it.getShortName()                                                                                                                        #
#       println "\"${plugin}\";"                                                                                                                              #
#       def deps =  it.getDependencies()                                                                                                                      #
#       deps.each {                                                                                                                                           #
#         def s = it.shortName                                                                                                                                #
#         println "\"${plugin}\" -> \"${s}\";"                                                                                                                #
#       }                                                                                                                                                     #
#   }                                                                                                                                                         #
#   println "}"                                                                                                                                               #
#                                                                                                                                                             #
#                                                                                                                                                             #
# Eklentileri jenkins.war dosyasından JENKINS'in eklentileri tuttuğu dizine çıkartıyoruz, böylece bu eklentileri yeni eklentilerle ezebiliriz                 #
# Ancak temiz bir kurulum için jenkins.war dosyası içindeki eklentileri açmak yerine doğrudan ilgilendiğimiz paketleri kurdurmayı tercih etmeliyiz.           #
#   RUN unzip -j -d ${PLUGIN_DIR} -n /usr/share/jenkins/jenkins.war WEB-INF/detached-plugins/* && \                                                           #
#       zip  -d /usr/share/jenkins/jenkins.war WEB-INF/detached-plugins/*                                                                                     #
#                                                                                                                                                             #
# Eklentileri kurmak için jenkins-plugin-manager{sürüm}.jar dosyasını kullanacağız.                                                                           #
#    https://github.com/jenkinsci/plugin-installation-manager-tool/releases/                                                                                  #
# adresindeki sürümlerden uygun olanı seçebiliriz                                                                                                             #
#                                                                                                                                                             #
#    https://github.com/jenkinsci/plugin-installation-manager-tool/releases/download/2.12.8/jenkins-plugin-manager-2.12.8.jar                                 #
#                                                                                                                                                             #
# jenkins.jar ile eklenti kurulumu da yapılabiliyor:                                                                                                          #
#   java -jar {{ jenkins_jar_location }} -s http://{{ jenkins_hostname }}:8080/ install-plugin {{ item }}                                                     #
#                                                                                                                                                             #
# Eklentileri yansının derlenmesi aşamasında da kurabiliriz:                                                                                                  #
#  RUN /usr/local/bin/jenkins-plugin-cli --plugins docker-plugin:1.2.3 job-dsl:1.78.1 workflow-aggregator:2.6 git:4.10.0 configuration-as-code:1.54 --verbose #
#  RUN /usr/local/bin/jenkins-plugin-cli --plugin-file /your/path/to/plugins.txt  --verbose                                                                   #
#                      java -jar jenkins-plugin-manager-*.jar --war /your/path/to/jenkins.war                                                                                                                                        #
#                                                                                                                                                             #
#                                                                                                                                                             #
#-------------------------------------------------------------------------------------------------------------------------------------------------------------#
ENV PLUGIN_DIR=${JENKINS_HOME}/plugins

COPY ./volume/plugins/ /tmp/plugins/
ARG YUKLENECEK_PLUGINS_DOSYASI=

RUN echo '#!/bin/bash \n env \n exec /bin/bash -c "java $JAVA_OPTS -jar /opt/jenkins-plugin-manager-2.12.8.jar $*"' > /usr/local/bin/jenkins-plugin-cli && \
    chmod +x /usr/local/bin/jenkins-plugin-cli

RUN mkdir $PLUGIN_DIR
RUN chown ${user_name}:${user_group_name} $PLUGIN_DIR
RUN [ -f "$YUKLENECEK_PLUGINS_DOSYASI" ] && jenkins-plugin-cli -f $YUKLENECEK_PLUGINS_DOSYASI --verbose || echo "yuklenecek plugins dosyasi yok"
# Veya eklentiler COPY komutuyla yansıya kopyalanır.
# COPY ./jenkins-plugins/plugins ${PLUGIN_DIR}


#-------------------------------------------------------------------------------------------------------------------------------------------------------------#
#                                                            DOSYA SAHİPLİĞİ                                                                                  #
#-------------------------------------------------------------------------------------------------------------------------------------------------------------#
# Jenkins dosyasını ilk olarak /usr/share/jenkins dizininde tuuyoruz bu yüzden sahipliğini almamız gerek
# Eğer JENKINS_HOME farklı bir dizin olursa diye onun da sahipliğini almalıyız aksi halde konteyner kullanıcısı permission denied hatası alacaktır.
RUN chown -R ${user_name}:${user_group_name} "$JENKINS_HOME" /usr/share/jenkins

RUN touch $COPY_REFERENCE_FILE_LOG && \
    chown ${user_name}:${user_group_name} $COPY_REFERENCE_FILE_LOG && \
    touch $COPY_REFERENCE_MARKER && \
    chown ${user_name}:${user_group_name} $COPY_REFERENCE_MARKER


#-------------------------------------------------------------------------------------------------------------------------------------------------------------#
#                                                            VARSAYILAN JOB AYARLARI                                                                          #
# Jenkins ayaklandığında yüklü olarak gelmesini istediğimiz job'ları ya config veya Job DSL CASC eklentisine uygun şekilde yükleyebiliriz.                    #
#                                                                                                                                                             #
#-------------------------------------------------------------------------------------------------------------------------------------------------------------#
ENV CASC_JENKINS_CONFIG $JENKINS_HOME/casc.yaml
COPY ./jcasc_plugin_confs/casc.yaml $JENKINS_HOME/casc.yaml

COPY ./etc-default-jenkins /etc/default/jenkins
RUN chown ${user_name}:${user_group_name} /etc/default/jenkins

#-------------------------------------------------------------------------------------------------------------------------------------------------------------#
#                                                            JOB BUILDS Dizinini harici bir yerde tutmak için                                                 #
#                                                                                                                                                             #
#-------------------------------------------------------------------------------------------------------------------------------------------------------------#
ARG JENKINS_BUILDS_DIR=${JENKINS_USER_HOME_DIR}/builds
RUN mkdir -p $JENKINS_BUILDS_DIR
RUN chown -R ${user_name}:${user_group_name} $JENKINS_BUILDS_DIR

# Eski paketleri ve güncelleme listelerini temizliyoruz
# RUN apt-get -qy autoremove && \
#     rm -rf /var/lib/apt/lists/*


COPY ./jenkins.sh /usr/local/bin/jenkins.sh
# RUN chown ${user_name}:${user_group_name} /usr/local/bin/jenkins.sh
RUN chmod 777 /usr/local/bin/jenkins.sh
RUN chown -R ${user_name}:${user_group_name} ${JENKINS_HOME}

# jobs Dizini
ENV JENKINS_JOBS_DIR=${JENKINS_HOME}/jobs
ENV JENKINS_SECRETS_DIR=${JENKINS_HOME}/secrets
ENV JENKINS_NODES_DIR=${JENKINS_HOME}/nodes
ENV JENKINS_USERS_DIR=${JENKINS_HOME}/users

RUN mkdir $JENKINS_JOBS_DIR
RUN mkdir $JENKINS_SECRETS_DIR
RUN mkdir $JENKINS_NODES_DIR
RUN mkdir $JENKINS_USERS_DIR
# Dışarıdan bağlanabilecek dizinlerin sahipliğini konteyner kullanıcısı (jenkins) üstüne alıyorum ki host üstünden
# bağlanan dizinler olursa erişim izni sorunu yaşamayalım.
RUN chown ${user_name}:${user_group_name} $JENKINS_JOBS_DIR  $JENKINS_SECRETS_DIR  $JENKINS_NODES_DIR  $JENKINS_USERS_DIR

VOLUME [ "$JENKINS_JOBS_DIR" ]
VOLUME [ "$JENKINS_SECRETS_DIR" ]
VOLUME [ "$JENKINS_NODES_DIR" ]
VOLUME [ "$JENKINS_USERS_DIR" ]
# Jenkins ana dizini yapılandırma kalıcı olabilir (host tarafında bir dizinle eşleştirilerek)
VOLUME [ "$JENKINS_HOME"]
VOLUME [ "$PLUGIN_DIR"]

USER ${user_name}

# Standard SSH port
EXPOSE 22
# web arayüzü için
EXPOSE 8090
# slave agent'lar tarafından kullanılacak
EXPOSE 50000

# Sadece bir executable için root kullanıcısı gerekmez
# CMD ["/usr/sbin/sshd", "-D"]
WORKDIR ${JENKINS_HOME}
CMD ["/usr/local/bin/jenkins.sh"]

# TODO: jenkins pipeline docker agent içinde çalışacak şekilde casc'a atılacak ve
# SCM adresinden uygulama çekilerek
# - derlenip (make build),
# - test edilip (make test),
# - debian paket oluşturulup (make dist_deb),
#   - paket havuzuna yüklenecek,
#       - deb havuzu container olarak ayaklanacak
# - docker yansısı yaratılıp (make dist_image),
#   - yansı repoya yüklenecek
#       - docker container olarak ayaklanacak
#
# - eventler açılacak ve global/projenin kütüphanesi bu olayları dinleyerek kendi işlerini yapacak
#
# - makefile yalınlaştırma
#   - makefile içinde bağımlı olduğu paketleri (kütüphaneleri) makefile etiketiyle kurmak (make install_prereq)
#   - makefile içindeki shell betiklerini dosyalara parçalamak (xxx.sh)
#
# - kubernetes
#   - NF'leri k8 içinde POD'larda ayaklandıracak
#   - k8 içinde bu süreçleri yönetmek (jenkins, repolar vs. POD olacak)
