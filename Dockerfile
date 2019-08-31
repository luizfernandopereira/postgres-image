FROM fedora
LABEL maitainer="Luiz Fernando Pereira <luizfernandopereira@outlook.com.br>" \
      company="Alternativa Informática"

RUN dnf install postgresql-server \
        procps-ng -y \
    && dnf clean all -y

ADD "entrypoint.sh" "/entrypoint.sh"
RUN chmod +x /entrypoint.sh

RUN mkdir -p /var/lib/pgsql/data && chown 26:26 /var/lib/pgsql/data

VOLUME "/var/lib/pgsql/data"

ENV PG_OOM_ADJUST_FILE=/proc/self/oom_score_adj
ENV PG_OOM_ADJUST_VALUE=0
ENV PGDATA=/var/lib/pgsql/data

USER postgres

EXPOSE 5432

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/postmaster -D ${PGDATA}"]