FROM ghcr.io/pacstall/pacstall:latest
LABEL org.opencontainers.image.description "Chaotic PPR"
ENV PPR_BASE="/home/pacstall/ppr-base"

COPY scripts/* /home/pacstall/ppr/

RUN /home/pacstall/ppr/setup.sh

EXPOSE 8000
WORKDIR /home/pacstall/ppr-base
CMD ["python3", "-m", "http.server"]
