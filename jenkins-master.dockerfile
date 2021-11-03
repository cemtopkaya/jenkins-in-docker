# https://devopscube.com/docker-containers-as-build-slaves-jenkins/#Configure_a_Docker_Host_With_Remote_API_Important
FROM ubuntu:xenial

RUN apt-get update && \
   apt-get install -y zip \
                      git \
                      curl \
                      gettext-base \
                      openjdk-8-jdk && \
   rm -rf /var/lib/apt/lists/*


# -----------------------------------------------------------------------------------------#
#                               JENKINS KURULUM SİHİRBAZI                                  #
# Jenkins master varsayılan olarak kurulum ile başlatılır. Kurulum yapmadan çalışması için #
# jenkins.install.runSetupWizard=false  işaretlenir.                                       #
#                                                                                          #
# -----------------------------------------------------------------------------------------#
ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false
# ENV JENKINS_OPTS --httpPort=-1 --httpsPort=8083 --httpsCertificate=/var/lib/jenkins/cert --httpsPrivateKey=/var/lib/jenkins/pk 
ENV JENKINS_OPTS=--httpPort=8083

ENV JENKINS_HOME /var/jenkins_home
ENV JENKINS_SLAVE_AGENT_PORT 50000
ENV JENKINS_UC https://updates.jenkins-ci.org
ENV COPY_REFERENCE_FILE_LOG /var/log/copy_reference_file.log
# referans dosyalarını yalnızca bir kez kopyaladığımızdan emin olmak için bayrak olarak kullanılan işaret dosyası
ENV COPY_REFERENCE_MARKER ${JENKINS_HOME}/.docker-onrun-complete

ENV JENKINS_HOME /var/jenkins_home
ARG user_name=jenkins
ARG user_password=jenkins
ARG user_group_name=jenkins
ARG user_id=1000
ARG user_group_id=1000
ARG root_password=sifre

# Make sure the package repository 6is up to date.
RUN apt-get update && \
    apt-get -qy full-upgrade && \
# This package includes the gettext and ngettext programs which allow other packages to internationalize the messages given by shell scripts.
    apt-get install -qy gettext-base

# Jenkins içinde çeşitli araçlara ihtiyaç oluyor: sshd, jdk, git, node, python vs.
RUN apt-get install -qy git && \
#-------------------------------------------------------------------------------------------------------------------------------------------------------------#
#                                                              SSH SERVER                                                                                     #
# SSH veya Secure Shell, iki bilgisayarın iletişim kurmasını (c.f http veya web sayfaları gibi köprü metni aktarmak için kullanılan protokol olan köprü metni #
# aktarım protokolü) ve verileri paylaşmasını sağlayan bir ağ iletişim protokolüdür.                                                                          #
#-------------------------------------------------------------------------------------------------------------------------------------------------------------#
    apt-get install -qy openssh-server && \
    sed -i 's|session    required     pam_loginuid.so|session    optional     pam_loginuid.so|g' /etc/pam.d/sshd && \
    mkdir -p /var/run/sshd && \
# Install JDK 8 (latest stable edition at 2019-04-01)
    apt-get install -qy openjdk-8-jdk && \
# Install maven
    # apt-get install -qy maven && \
# Cleanup old packages
    apt-get -qy autoremove

#ADD settings.xml /home/jenkins/.m2/

# SSH sunucusu çalışsın diye /var/run/sshd dizinini yaratıyoruz
RUN mkdir -p /var/run/sshd
# jenkins Adında bir grup oluşturup
RUN groupadd -g ${user_group_id} ${user_group_name}
# jenkins adında  bir kullanıcıyı bu gruba ekliyoruz 
RUN useradd -c "Jenkins kullanici aciklamasi" -d "$JENKINS_HOME" -u ${user_id} -g ${user_group_id} -m ${user_name} -s /bin/bash
RUN echo "${user_name}:${user_password}" | chpasswd
# jenkins kullanıcısını sudoers grubuna her işlemi bir daha şifre sormadan yapabilsin diye ekliyoruz 
# RUN echo "${user_name}  ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers.d/${user_name} && chmod 0440 /etc/sudoers.d/${user_name}
# Bu konteynere root kullanıcısını kullanarak SSH protokolüyle bağlanmak istediğimizde şifreyi sshpass ile geçirebilmek için ayarlayalım
RUN echo 'root:${root_password}' | chpasswd
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
# RUN service ssh restart
# Bu konteynere jenkins kullanıcısını kullanarak SSH ile bağlanmak istersek iki türlü kullanıcı doğrulaması yapılır:
# 1. jenkins Kullanıcı adı ve şifresiyle ($ sshpass -p 'jenkins-sifresi' ssh -o StrictHostKeyChecking=no jenkins@konteyner_ip)
# 2. jenkins Kullanıcısının ev dizinin altındaki .ssh dizininde olan açık-gizli anahtar ikilisiyle
RUN mkdir ${JENKINS_HOME}/.ssh && \
    chown -R ${user_name} ${JENKINS_HOME}/.ssh && \
    chmod 700 ${JENKINS_HOME}/.ssh && \
    cd ${JENKINS_HOME}/.ssh && \
# jenkins Kullanıcısı için açık-gizli anahtarı (gizli anahtarı şifresiz olarak) oluşturuyoruz
    ssh-keygen -q -t rsa -N '' -f ${JENKINS_HOME}/.ssh/id_rsa && \
# jenkins Kullanıcısıyla SSH yapılırken açık anahtar ile doğrulama yapılırsa "yetki verilen anahtarlar" dosyasına açık anahtarı ekliyoruz
# Elbette bu açık anahtarın istemciye eklenmesi ve /home/istemcideki_baglanti_yapacak_kullanicinin/.ssh/config dosyasında ayarların yapılması gerekiyor
# Bkz. https://github.com/cemtopkaya/dockerfile_jenkinsfile/blob/main/Dockerfile 
    cat ${JENKINS_HOME}/.ssh/id_rsa.pub > ${JENKINS_HOME}/.ssh/authorized_keys && \
# Sunucudaki sertifikalar güncellenir ve /etc/ssl/certs dizini jenkins kullanıcısına sahiplendirilir
    update-ca-certificates && \
    chown -R ${user_name}:${user_group_name} /etc/ssl/certs/ 

# Jenkins ana dizini yapılandırma kalıcı olabilir (host tarafında bir dizinle eşleştirilerek)
VOLUME [ "$JENKINS_HOME"]

#------------------------------------------------------------------------------------------------------------------------------------------------------------#
#                                           JENKINS KURULUMU                                                                                                 #
# jenkins.war uygulaması Jenkins olarak çalışacak ancak eklentiler, ayar dosyaları gibi ek ayarlara ihtiyacımız olack.                                       #
#                                                                                                                                                            #
#------------------------------------------------------------------------------------------------------------------------------------------------------------#
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

# COPY ./jenkins.war /usr/share/jenkins/jenkins.war
ADD http://mirrors.jenkins-ci.org/war-stable/latest/jenkins.war /usr/share/jenkins/jenkins.war

# RUN curl -L http://mirrors.jenkins-ci.org/war-stable/latest/ -o /usr/share/jenkins/jenkins.war

# eklentileri jenkins.war dosyasından ref dizinine çıkartıyoruz, böylece bu eklentileri yeni eklentilerle ezebiliriz
RUN unzip -j -d /usr/share/jenkins/ref/plugins -n /usr/share/jenkins/jenkins.war WEB-INF/detached-plugins/* && \
    zip  -d /usr/share/jenkins/jenkins.war WEB-INF/detached-plugins/*

RUN chown -R ${user_name} "$JENKINS_HOME" /usr/share/jenkins /usr/share/jenkins/ref

RUN touch $COPY_REFERENCE_FILE_LOG && \
    chown ${user_name}.${user_group_name} $COPY_REFERENCE_FILE_LOG

RUN touch $COPY_REFERENCE_MARKER && chown ${user_name}.${user_group_name} $COPY_REFERENCE_MARKER


#------------------------------------------------------------------------------------------------------------------------------------------------------------#
#                                           DOCKER-CE-CLI KURULUMU                                                                                           #
# Docker paketlerinden istemci paketini kurup sunucu olarak başka bir docker host'u göstereceğiz. DOCKER_HOST konteynerin hostu olacak (window için)         #
#                                                                                                                                                            #
#------------------------------------------------------------------------------------------------------------------------------------------------------------#
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
RUN echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu xenial stable" > /etc/apt/sources.list.d/docker.list
RUN apt-get install -y apt-transport-https
RUN apt-get update 
RUN apt-get install -y docker-ce-cli

USER ${user_name}

# docker host sunucusu olarak kendi hostunu gösteriyoruz ancak değiştirilebilir.
ENV DOCKER_HOST=tcp://host.docker.internal:2375

# Standard SSH port
EXPOSE 22
# web arayüzü için
EXPOSE 8080
# slave agent'lar tarafından kullanılacak
EXPOSE 50000

# Sadece bir executable için root kullanıcısı gerekmez
# CMD ["/usr/sbin/sshd", "-D"]

COPY ./jenkins.sh /usr/local/bin/jenkins.sh
ENTRYPOINT ["/usr/local/bin/jenkins.sh"]