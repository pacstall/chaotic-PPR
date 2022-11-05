FROM ghcr.io/pacstall/pacstall:latest
LABEL org.opencontainers.image.description "Chaotic PPR"
ENV TERM='xterm-256color'

RUN sudo apt install inotify-tools -y

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
