# https://devopscube.com/docker-containers-as-build-slaves-jenkins/#Configure_a_Docker_Host_With_Remote_API_Important
FROM ubuntu:xenial

# Make sure the package repository 6is up to date.
RUN apt-get update && \
    apt-get -qy full-upgrade && \
# Install git client for repo stuffes
    apt-get install -qy git && \
# Install a basic SSH server
    apt-get install -qy openssh-server

RUN sed -i 's|session    required     pam_loginuid.so|session    optional     pam_loginuid.so|g' /etc/pam.d/sshd && \
    mkdir -p /var/run/sshd && \
# Install JDK 8 (latest stable edition at 2019-04-01)
    apt-get install -qy openjdk-8-jdk && \
# Install maven
    # apt-get install -qy maven && \
# Cleanup old packages
    apt-get -qy autoremove

#ADD settings.xml /home/jenkins/.m2/

# Add user jenkins to the image
RUN useradd -rm -d /home/jenkins -s /bin/bash -g root -G sudo -u 1001 jenkins
# Set password for the jenkins user (you may want to alter this).
RUN echo "jenkins:jenkins" | chpasswd && \
    mkdir /home/jenkins/.m2

# Copy authorized keys
RUN mkdir -p /home/jenkins/.ssh
RUN echo "" > /home/jenkins/.ssh/authorized_keys

RUN chown -R jenkins:jenkins /home/jenkins/.m2/ && \
    chown -R jenkins:jenkins /home/jenkins/.ssh/


# Standard SSH port
EXPOSE 22

# CMD ["/usr/sbin/sshd", "-D"]
CMD ["/sbin/init"]