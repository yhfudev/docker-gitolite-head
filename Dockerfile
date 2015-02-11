# Gitolite server
#
# Example:
# 	Build:
#		 docker build -t gitolite .
#
# 	Run:
#    docker run -d --name gitolite -p 22022:22 -v /var/data/git:/home/git/repositories -e SSH_KEY="$(cat ~/.ssh/id_rsa.pub)"  gitolite

FROM ubuntu
MAINTAINER Beta CZ <hlj8080@gmail.com>

ENV http_proxy 'http://192.168.3.5:3128'
ENV https_proxy 'http://192.168.3.5:3128'
ENV HTTP_PROXY 'http://192.168.3.5:3128'
ENV HTTPS_PROXY 'http://192.168.3.5:3128'

RUN echo 'd-i apt-setup/no_mirror boolean true' | debconf-set-selections
RUN echo 'd-i mirror/http/hostname string http.us.debian.org' | debconf-set-selections
RUN echo 'd-i mirror/http/directory string /debian' | debconf-set-selections
RUN echo 'd-i mirror/http/proxy string' | debconf-set-selections

# install requirements
RUN apt-get update
RUN apt-get install -y git perl openssh-server

RUN locale-gen en_US.UTF-8
RUN dpkg-reconfigure locales

#ENV DEBIAN_FRONTEND noninteractive
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# create 'git' user
RUN useradd git -m

# install gitolite
RUN su - git -c 'git clone git://github.com/sitaramc/gitolite'
RUN su - git -c 'mkdir -p $HOME/bin \
	&& gitolite/install -to $HOME/bin'

ADD adminkey.pub /home/git/adminkey.pub
# setup with built-in ssh key
#RUN ssh-keygen -f adminkey -t rsa -N ''
RUN su - git -c '$HOME/bin/gitolite setup -pk adminkey.pub'

# prevent the perl warning
RUN sed  -i 's/AcceptEnv/# \0/' /etc/ssh/sshd_config

# fix fatal: protocol error: bad line length character: Welc
RUN sed -i 's/session\s\+required\s\+pam_loginuid.so/# \0/' /etc/pam.d/sshd

RUN mkdir /var/run/sshd

ADD start.sh /start.sh
RUN chmod a+x /start.sh

RUN chown -R git:git /home/git

EXPOSE 22
CMD ["/start.sh"]
