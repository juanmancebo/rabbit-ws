FROM jenkins/jenkins:lts
USER root
COPY run.sh plugins.txt /usr/share/jenkins/ref/
RUN /usr/share/jenkins/ref/run.sh
USER jenkins
