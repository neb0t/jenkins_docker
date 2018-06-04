FROM centos:7

ARG HTTP_PORT=8080
ARG SLAVE_PORT=55001

ENV JENKINS_HOME /var/jenkins_home
ENV JENKINS_SLAVE_AGENT_PORT ${SLAVE_PORT}
ENV JENKINS_OPTS "-Djenkins.install.runSetupWizard=false"
ENV JENKINS_UC https://updates.jenkins-ci.org
ENV JAVA_PATH 512cd62ec5174c3487ac17c61aaa89e8
ENV JAVA_VERSION 8
ENV JAVA_UPDATE 171
ENV JAVA_BUILD 11

VOLUME /var/jenkins_home

RUN mkdir -p /usr/share/jenkins/ref/init.groovy.d

RUN yum install -y yum-utils \
    device-mapper-persistent-data \
    lvm2 openssh git

#RUN yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
#RUN yum-config-manager --enable docker-ce-edge
RUN yum -y install epel-release yum-utils zip unzip wget curl which
RUN yum-config-manager --add-repo https://packages.docker.com/1.12/yum/repo/main/centos/7
RUN yum -y install docker jq maven
#RUN yum -y install docker-ce jq

ENV TINI_VERSION 0.16.1
ENV TINI_SHA 5e01734c8b2e6429a1ebcc67e2d86d3bb0c4574dd7819a0aff2dca784580e040

# Use tini as subreaper in Docker container to adopt zombie processes
RUN curl -fsSL https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini-static-amd64 -o /bin/tini && chmod +x /bin/tini \
  && echo "$TINI_SHA  /bin/tini" | sha256sum -c -

RUN wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/${JAVA_VERSION}u${JAVA_UPDATE}-b${JAVA_BUILD}/${JAVA_PATH}/jdk-${JAVA_VERSION}u${JAVA_UPDATE}-linux-x64.rpm" -O /tmp/jdk.rpm

RUN rpm -Uvi /tmp/jdk.rpm && rm /tmp/jdk.rpm

COPY init.groovy /usr/share/jenkins/ref/init.groovy.d/tcp-slave-agent-port.groovy

# jenkins version being bundled in this docker image
ARG JENKINS_VERSION
ENV JENKINS_VERSION ${JENKINS_VERSION:-2.107.3}

# jenkins.war checksum, download will be validated using it
ARG JENKINS_SHA=17a9e509bec5b16bde5b50bc7f59d5f1e458a55fe433deb86fd73b865bf89ab8
# Can be used to customize where jenkins.war get downloaded from
ARG JENKINS_URL=https://repo.jenkins-ci.org/public/org/jenkins-ci/main/jenkins-war/${JENKINS_VERSION}/jenkins-war-${JENKINS_VERSION}.war

# could use ADD but this one does not check Last-Modified header neither does it allow to control checksum
# see https://github.com/docker/docker/issues/8331
RUN curl -fsSL ${JENKINS_URL} -o /usr/share/jenkins/jenkins.war \
#RUN curl -fsSL ${JENKINS_URL} -o /usr/share/jenkins/jenkins.war
  && echo "${JENKINS_SHA}  /usr/share/jenkins/jenkins.war" | sha256sum -c -

ENV JENKINS_UC https://updates.jenkins.io

EXPOSE ${HTTP_PORT}
EXPOSE ${SLAVE_PORT}

ENV COPY_REFERENCE_FILE_LOG $JENKINS_HOME/copy_reference_file.log

COPY jenkins-support /usr/local/bin/jenkins-support
COPY jenkins.sh /usr/local/bin/jenkins.sh

COPY plugins.sh /usr/local/bin/plugins.sh
COPY install-plugins.sh /usr/local/bin/install-plugins.sh
COPY resources/plugins.txt /usr/share/jenkins/ref/
COPY resources/init.groovy.d/ /usr/share/jenkins/ref/init.groovy.d/

RUN /usr/local/bin/plugins.sh /usr/share/jenkins/ref/plugins.txt

ENTRYPOINT ["/bin/tini", "--", "/usr/local/bin/jenkins.sh"]

