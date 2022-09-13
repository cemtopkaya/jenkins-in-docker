# ---------------------------------------------------------------------------------------------------------------------------------------------------------#
#                               KOMUTLAR VE AÇIKLAMALARI                                                                                                   #
#                                                                                                                                                          #
# docker build --add-host security.ubuntu.com:91.189.91.39  `                                                                                               #
#              -t cemo                                      `                                                                                               #
#              -f .\jenkins-master.dockerfile .                                                                                                            #
#                                                                                                                                                          #
# docker run -it --rm                                        `                                                                                             #
#            -p 8090:8090                                    `                                                                                             #
#            -e JENKINS_OPTS=--httpPort=8090                 `                                                                                             #
#            -e DOCKER_HOST=tcp://host.docker.internal:2375  `                                                                                             #
#            --dns 176.31.121.197                            `                                                                                             #
#            --add-host archive.ubuntu.com:91.189.88.142     `                                                                                             #
#            --add-host security.ubuntu.com:91.189.88.142    `                                                                                             #
#            --add-host updates.jenkins.io:52.202.51.185     `                                                                                             #
#            --add-host get.jenkins.io:52.167.253.43         `                                                                                             #
#            --name jendock                                  `                                                                                             #
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
    apt-get update && \
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
RUN curl --create-dirs -fL http://mirrors.jenkins-ci.org/war-stable/latest/jenkins.war -o /usr/share/jenkins/jenkins.war
# ADD http://mirrors.jenkins-ci.org/war-stable/latest/jenkins.war /usr/share/jenkins/jenkins.war
# COPY ./bin/jenkins-2.303.2.war /usr/share/jenkins/jenkins.war

RUN curl --create-dirs -fL https://github.com/jenkinsci/plugin-installation-manager-tool/releases/download/2.12.8/jenkins-plugin-manager-2.12.8.jar -o /opt/jenkins-plugin-manager-2.12.8.jar
# ADD https://github.com/jenkinsci/plugin-installation-manager-tool/releases/download/2.12.8/jenkins-plugin-manager-2.12.8.jar /opt/jenkins-plugin-manager-2.12.8.jar
# COPY ./bin/jenkins-plugin-manager-2.12.8.jar ./jenkins-plugins/plugins.yaml /opt/







# -----------------------------------------------------------------------------------------#
#                               JENKINS KURULUM SİHİRBAZI                                  #
# Jenkins tanımları ve ayarları için bu stage kullanılacaktır.                             #
# -----------------------------------------------------------------------------------------#
FROM jenkins-base

# -----------------------------------------------------------------------------------------#
#                               JENKINS KURULUM SİHİRBAZI                                  #
# Jenkins master varsayılan olarak kurulum ile başlatılır. Kurulum yapmadan çalışması için #
# jenkins.install.runSetupWizard=false  işaretlenir.                                       #
#                                                                                          #
# -----------------------------------------------------------------------------------------#
ENV JENKINS_HOME /var/jenkins_home
ARG user_name=jenkins
ARG user_password=jenkins
ARG user_group_name=jenkins
ARG user_id=1000
ARG user_group_id=1000
ARG root_password=sifre

#-------------------------------------------------------------------------------------------------------------------------------------------------------------#
#                                                              KULLANICI-GRUP AYARLARI                                                                        #
# jenkins adında bir kullanıcıyı jenkins adında bir grup içinde oluşturacağız.                                                                                #
# Eğer sudo paketi kuruluysa jenkins kullanıcısını sudoers grubuna şifre istemeden super user olarak işlemleri yapacak şekilde ekleyeceğiz.                   #
# jenkins kullanıcısının ev dizini jenkins uyglamasının çalışacağı yer olacak.                                                                                #
# Hem jenkins hem root kullanıcısının şifrelerini SSH bağlantılarını yapabilmek için tayin edeceğiz.                                                          #
#-------------------------------------------------------------------------------------------------------------------------------------------------------------#
# jenkins Adında bir grup oluşturup
RUN groupadd -g ${user_group_id} ${user_group_name}
# jenkins adında  bir kullanıcıyı bu gruba ekliyoruz 
RUN useradd -c "Jenkins kullanici aciklamasi" -d "$JENKINS_HOME" -u ${user_id} -g ${user_group_id} -m ${user_name} -s /bin/bash
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
    mkdir ${JENKINS_HOME}/.ssh && \
    chown -R ${user_name} ${JENKINS_HOME}/.ssh && \
    chmod 700 ${JENKINS_HOME}/.ssh && \
    cd ${JENKINS_HOME}/.ssh && \
    # jenkins Kullanıcısı için açık-gizli anahtarı (gizli anahtarı şifresiz olarak) oluşturuyoruz
    ssh-keygen -q -t rsa -N '' -f ${JENKINS_HOME}/.ssh/id_rsa && \
    # jenkins Kullanıcısıyla SSH yapılırken açık anahtar ile doğrulama yapılırsa "yetki verilen anahtarlar" dosyasına açık anahtarı ekliyoruz
    # Elbette bu açık anahtarın istemciye eklenmesi ve /home/istemcideki_baglanti_yapacak_kullanicinin/.ssh/config dosyasında ayarların yapılması gerekiyor
    # Bkz. https://github.com/cemtopkaya/dockerfile_jenkinsfile/blob/main/Dockerfile 
    cat ${JENKINS_HOME}/.ssh/id_rsa.pub > ${JENKINS_HOME}/.ssh/authorized_keys


#-------------------------------------------------------------------------------------------------------------------------------------------------------------#
#                                                            SERTİFİKA AYARLARI                                                                               #
# Sunucudaki sertifikalar güncellenir ve /etc/ssl/certs dizini jenkins kullanıcısına sahiplendirilir                                                          #
#-------------------------------------------------------------------------------------------------------------------------------------------------------------#
RUN update-ca-certificates && \
    chown -R ${user_name}:${user_group_name} /etc/ssl/certs/


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
#------------------------------------------------------------------------------------------------------------------------------------------------------------#
ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false
# ENV JENKINS_OPTS --httpPort=-1 --httpsPort=8083 --httpsCertificate=/var/lib/jenkins/cert --httpsPrivateKey=/var/lib/jenkins/pk 
ENV JENKINS_OPTS=--httpPort=8090
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
#                                                                                                                                                             #
#-------------------------------------------------------------------------------------------------------------------------------------------------------------#
ENV PLUGIN_DIR=${JENKINS_HOME}/plugins

RUN echo '#!/bin/bash \n env \n exec /bin/bash -c "java $JAVA_OPTS -jar /opt/jenkins-plugin-manager-2.12.8.jar $*"' > /usr/local/bin/jenkins-plugin-cli && \
    chmod +x /usr/local/bin/jenkins-plugin-cli
# RUN jenkins-plugin-cli -f /opt/plugins.yaml --verbose
RUN [ -f "/opt/plugins.yaml" ] && jenkins-plugin-cli -f /opt/plugins.yaml --verbose || echo "plugins.yaml dosyasi yok"
# Veya eklentiler COPY komutuyla yansıya kopyalanır.
# COPY ./jenkins-plugins/plugins ${PLUGIN_DIR}


#-------------------------------------------------------------------------------------------------------------------------------------------------------------#
#                                                            DOSYA SAHİPLİĞİ                                                                                  #
#-------------------------------------------------------------------------------------------------------------------------------------------------------------#
RUN chown -R ${user_name} "$JENKINS_HOME" /usr/share/jenkins /usr/share/jenkins/ref

RUN touch $COPY_REFERENCE_FILE_LOG && \
    chown ${user_name}.${user_group_name} $COPY_REFERENCE_FILE_LOG && \
    touch $COPY_REFERENCE_MARKER && \
    chown ${user_name}.${user_group_name} $COPY_REFERENCE_MARKER


#-------------------------------------------------------------------------------------------------------------------------------------------------------------#
#                                                            VARSAYILAN JOB AYARLARI                                                                          #
# Jenkins ayaklandığında yüklü olarak gelmesini istediğimiz job'ları ya config veya Job DSL CASC eklentisine uygun şekilde yükleyebiliriz.                    #
#                                                                                                                                                             #
#-------------------------------------------------------------------------------------------------------------------------------------------------------------#
ENV CASC_JENKINS_CONFIG /var/jenkins_home/casc.yaml
COPY ./jcasc_plugin_confs/casc.yaml /var/jenkins_home/casc.yaml

# Eski paketleri ve güncelleme listelerini temizliyoruz
# RUN apt-get -qy autoremove && \
#     rm -rf /var/lib/apt/lists/*

RUN rm /etc/ssl/certs/java/cacerts && update-ca-certificates -f

COPY ./jenkins.sh /usr/local/bin/jenkins.sh
# RUN chown ${user_name}:${user_group_name} /usr/local/bin/jenkins.sh
RUN chmod 777 /usr/local/bin/jenkins.sh
RUN chown -R ${user_name}:${user_group_name} ${JENKINS_HOME}

USER ${user_name}

# Standard SSH port
EXPOSE 22
# web arayüzü için
EXPOSE 8090
# slave agent'lar tarafından kullanılacak
EXPOSE 50000

# Sadece bir executable için root kullanıcısı gerekmez
# CMD ["/usr/sbin/sshd", "-D"]

# Jenkins ana dizini yapılandırma kalıcı olabilir (host tarafında bir dizinle eşleştirilerek)
VOLUME [ "$JENKINS_HOME"]

COPY ./jenkins.sh /usr/local/bin/jenkins.sh
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
