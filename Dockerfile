FROM ghcr.io/pacstall/pacstall:latest
LABEL org.opencontainers.image.description "Chaotic PPR"
ENV PPR_BASE="/home/pacstall/ppr-base"
ENV TERM='xterm-256color'

RUN sudo apt install inotify-tools -y
COPY scripts/* /var/ppr/scripts/
RUN mkdir -p /home/pacstall/ppr-base/
RUN sudo chown -R pacstall:pacstall /home/pacstall/ppr-base/
COPY ppr.pub /home/pacstall/ppr-base/
COPY private-ppr.txt /var/gpg/

WORKDIR /home/pacstall/ppr-base
USER pacstall

EXPOSE 8000
#CMD ["python3", "-m", "http.server"]
CMD ["bash", "/var/ppr/scripts/setup.sh"]
