FROM fedora
LABEL maitainer="Luiz Fernando Pereira <luizfernandopereira@outlook.com.br>"

RUN dnf install postgresql-server \
        procps-ng \
        postgresql-contrib -y \
    && dnf clean all -y

ENV TIMEZONE=America/Sao_Paulo
RUN ln -snf /usr/share/zoneinfo/$TIMEZONE /etc/localtime && echo $TIMEZONE > /etc/timezone

ADD "entrypoint.sh" "/entrypoint.sh"
RUN chmod +x /entrypoint.sh

COPY postgresql.conf /postgresql.conf

RUN mkdir -p /var/lib/pgsql/data && chown 26:26 /var/lib/pgsql/data

VOLUME "/var/lib/pgsql/data"

ENV PG_OOM_ADJUST_FILE=/proc/self/oom_score_adj
ENV PG_OOM_ADJUST_VALUE=0
ENV PGDATA=/var/lib/pgsql/data

USER postgres

EXPOSE 5432

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/postmaster -D ${PGDATA}"]