#!/bin/bash
set -m

/usr/libexec/postgresql-check-db-dir %N

if [ $? -ne 0 ]
then
    initdb -D ${PGDATA}

    if [ $? -eq 0 ]
    then
        rm -f /var/lib/pgsql/data/postgresql.conf
        cp /postgresql.conf /var/lib/pgsql/data/postgresql.conf
        sudo rm -f /postgresql.conf

        if [ -n "$TIMEZONE" ]; then
            sudo ln -snf /usr/share/zoneinfo/$TIMEZONE /etc/localtime && sudo echo $TIMEZONE > /etc/timezone
            echo "log_timezone = '$TIMEZONE'" >> /var/lib/pgsql/data/postgresql.conf
            echo "timezone = '$TIMEZONE'" >> /var/lib/pgsql/data/postgresql.conf
        fi

        cat > "/var/lib/pgsql/data/pg_hba.conf" <<EOF
        # PostgreSQL Client Authentication Configuration File
        # ===================================================
        #
        # Note that this is auto-generated file by $0 script.  If you
        # wan't to change this file, the quick syntax documentation may be found in
        # /usr/share/pgsql/pg_hba.conf.sample file.

        # TYPE  DATABASE        USER            ADDRESS                 METHOD
        # --------------------------------------------------------------------
        local   all             postgres                                peer
        local   all             all                                     md5
        host    all             all             ::/0                    md5
        host    all             all             0.0.0.0/0               md5
EOF

        /usr/bin/postmaster -D ${PGDATA} &

        sleep 10s

        if [ -z "$POSTGRESQL_ADMIN_PASSWORD" ]; then
            POSTGRESQL_ADMIN_PASSWORD=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 12 ;)
            echo "Admin password not supplied."
            echo "The default password for user postgres is: $POSTGRESQL_ADMIN_PASSWORD"
            echo "You can change it later."
        else
            psql -c "ALTER USER postgres with encrypted password '$POSTGRESQL_ADMIN_PASSWORD'"

            if test -n "$POSTGRESQL_DATABASE" \
                && test -n "$POSTGRESQL_USER" \
                && test -n "$POSTGRESQL_PASSWORD"
            then
                echo "Creating database '$POSTGRESQL_DATABASE' for the user $POSTGRESQL_USER"

                psql -c "CREATE USER $POSTGRESQL_USER SUPERUSER INHERIT CREATEDB CREATEROLE; "
                psql -c "ALTER USER $POSTGRESQL_USER with encrypted password '$POSTGRESQL_PASSWORD'"
        
                psql -c "CREATE DATABASE $POSTGRESQL_DATABASE
                                    WITH
                                    OWNER = $POSTGRESQL_USER
                                    TABLESPACE = pg_default
                                    CONNECTION LIMIT = -1;"
        
                psql -c "CREATE SCHEMA $POSTGRESQL_DATABASE;"
            fi
        fi
        fg %1
    else
        exit $?
    fi
fi

/usr/bin/postmaster -D ${PGDATA}