#!/bin/bash

NAME="sitio"
DJANGODIR=/home/ubuntu/repositorios/aurora/gestor_usuarios/backend
SOCKFILE=/home/ubuntu/repositorios/aurora/gestor_usuarios/backend/env/run/gunicorn.sock
TIMEOUT=60
USER=ubuntu
GROUP=ubuntu
NUM_WORKERS=4
DJANGO_SETTINGS_MODULE=conf.settings
DJANGO_WSGI_MODULE=conf.wsgi
VIRTUALENV_BIN=/home/ubuntu/ciencia/sitio-backend/env/bin
NOW=$(date +'%d/%m/%Y %T')

echo "[$NOW] STARTING GUNICORN PROJECT $NAME AS `whoami` USER"
cd $DJANGODIR
source $VIRTUALENV_BIN/activate
echo "[$NOW] ACTIVATING VIRTUALENV $VIRTUEALENV_BIN"
export DJANGO_SETTINGS_MODULE=$DJANGO_SETTINGS_MODULE
echo  "[$NOW] EXPORTING DJANGO PROJECT $DJANGODIR"
export PYTHONPATH=$DJANGODIR:$PYTHONPATH

echo "[$NOW] GENERATING SOCKECT FILE $SOCKFILE"
RUNDIR=$(dirname $SOCKFILE)
test -d $RUNDIR || mkdir -p $RUNDIR

#Start gunicorn
exec  $VIRTUALENV_BIN/gunicorn ${DJANGO_WSGI_MODULE}:application \
        --name $NAME \
        --workers $NUM_WORKERS \
        --timeout $TIMEOUT \
        --user $USER \
        --group $GROUP \
        --bind unix:$SOCKFILE \
        --log-level info \
        --limit-request-line 12000 \
        --log-file - \
        --reload \
