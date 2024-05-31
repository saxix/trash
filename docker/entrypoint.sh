#!/bin/bash

set -eou pipefail

production() {
    uwsgi \
        --http :8000 \
        --master \
        --module=hope_dedup_engine.config.wsgi \
        --processes=2 \
        --buffer-size=8192
}

if [ $# -eq 0 ]; then
    production
fi

case "$1" in
    dev)
        wait-for-it.sh db:5432
        ./manage.py upgrade
        ./manage.py runserver 0.0.0.0:8000
    ;;
    prd)
        tail -f /dev/null
        production
    ;;
    celery_worker)
        export C_FORCE_ROOT=1
        celery -A hope_dedup_engine.config.celery worker -l info
    ;;
    celery_beat)
        celery -A hope_dedup_engine.config.celery beat -l info
    ;;
    *)
        exec "$@"
    ;;
esac