#!/bin/bash
set -e

if [ -n "$PASSWORD_FILE" ]; then
    PASSWORD="$(< $PASSWORD_FILE)"
fi

: ${HOST:=${DB_PORT_5432_TCP_ADDR:='db'}}
: ${PORT:=${DB_PORT_5432_TCP_PORT:=5432}}
: ${USER:=${DB_ENV_POSTGRES_USER:=${POSTGRES_USER:='odoo'}}}
: ${PASSWORD:=${DB_ENV_POSTGRES_PASSWORD:=${POSTGRES_PASSWORD:='odoo'}}}

DB_ARGS=""
check_config() {
    param="$1"
    value="$2"
    if grep -q -E "^\s*\b${param}\b\s*=" "$ODOO_RC"; then
        value=$(grep -E "^\s*\b${param}\b\s*=" "$ODOO_RC" | cut -d " " -f3 | sed 's/["\n\r]//g')
    fi;
    DB_ARGS="$DB_ARGS --${param} ${value}"
}
check_config "db_host" "$HOST"
check_config "db_port" "$PORT"
check_config "db_user" "$USER"
check_config "db_password" "$PASSWORD"

case "$1" in
    -- | odoo)
        shift
        if [[ "$1" == "scaffold" ]]; then
            exec odoo "$@"
        else
            /usr/local/bin/wait-for-psql.py $DB_ARGS --timeout=30
            exec odoo "$@" $DB_ARGS
        fi
        ;;
    -*)
        /usr/local/bin/wait-for-psql.py $DB_ARGS --timeout=30
        exec odoo "$@" $DB_ARGS
        ;;
    *)
        exec "$@"
        ;;
esac

exit 1
