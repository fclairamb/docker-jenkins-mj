# See https://github.com/jenkinsci/docker
FROM debian

USER root

# We update
RUN apt-get update -y

# We need a basic system
RUN apt-get install rsyslog ssh -y

# We get our notification tools
RUN apt-get install python-pip -y
RUN pip install pygments

# Let's install some mailing tools
#RUN echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections
RUN DEBIAN_FRONTEND=noninteractive apt-get install mailutils postfix -y

# Let's install java
RUN \
  echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu precise main" > /etc/apt/sources.list.d/webupd8team-java.list && \
  apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886 && \
  echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  apt-get update && \
  apt-get install -y oracle-java8-installer && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /var/cache/oracle-jdk8-installer

# Let's install JENKINS
RUN useradd -d /var/lib/jenkins -u 1000 -m -s /bin/bash jenkins
VOLUME /var/lib/jenkins
RUN \
	apt-get install wget -y && \
	echo deb http://pkg.jenkins-ci.org/debian binary/ > /etc/apt/sources.list.d/jenkins.list && \
	wget -q -O - https://jenkins-ci.org/debian/jenkins-ci.org.key | apt-key add - && \
	apt-get update && \
	apt-get install jenkins net-tools -y && \
	chown jenkins /var/lib/jenkins -Rf
EXPOSE 8080

# We'll also make jenkins able to sudo. The point here is to allow jobs to 
# install new programs without having to modify the docker instance all the
# time. It means a job can break the jenkins instance, but it's easy to fix
# (just restart one), the important stuff is stored with the jenkins user 
# access anyway. And we trust others to have good intentions.
RUN apt-get install sudo -y
RUN echo "jenkins ALL= NOPASSWD: ALL" >>/etc/sudoers

# We get our build tools
RUN apt-get install make g++ subversion -y

# It's useful only for testing...
RUN apt-get install vim -y

# Postfix basic setup
# Some servers will refuse our emails if we don't do this.
RUN postconf -e myhostname=florent.clairambault.fr mydomain=clairambault.fr

# Timezone fix
RUN echo Europe/Paris > /etc/timezone && dpkg-reconfigure --frontend noninteractive tzdata

# We setup a start point
COPY start.sh /usr/local/bin/start.sh
ENTRYPOINT /usr/local/bin/start.sh

#USER jenkins
