FROM ubuntu:latest
LABEL org.opencontainers.image.description "Chaotic PPR"

# ENV setup
ENV TERM='xterm-256color'
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ="Africa/Libreville"
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install required packages
RUN apt-get update
RUN apt-get install sudo inotify-tools gpg -y

# Setup user
RUN adduser --disabled-password --gecos '' pacstall
RUN adduser pacstall sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Chaotic PPR scripts
COPY scripts/* /var/ppr/scripts/
RUN mkdir -p /home/pacstall/ppr-base/
RUN sudo chown -R pacstall:pacstall /home/pacstall/ppr-base/
RUN sudo chmod 755 /home/pacstall/ppr-base/
COPY ppr.pub /home/pacstall/ppr-base/
COPY private-ppr.txt /var/gpg/

RUN gpg --import /var/gpg/private-ppr.txt
RUN gpg --import /home/pacstall/ppr-base/ppr.pub

WORKDIR /home/pacstall/ppr-base
USER pacstall

CMD ["bash", "/var/ppr/scripts/setup.sh"]
