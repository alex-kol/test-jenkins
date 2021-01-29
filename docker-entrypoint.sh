#!/bin/bash

#
# Hydra-API docker entrypoint, that can process running of:
# 1) backend
# 2) worker
# 3) nginx reverse proxy service
#

set -e

function get_time() {
   echo "$(date '+%D %T')"
}

function runcmd() {
  echo "$(get_time). Running command: $1"
  $1
}

ENVIRONMENT=${ENVIRONMENT:-production}
STORAGE_FOLDER=${STORAGE_FOLDER:-${BASE_PATH:-/var/www/html/laravelapp}/storage}

if [ "$1" == "backend" ]; then
  #
  # Backend (php-fpm)
  #
  echo "Running Hydra-API Backend (${ENVIRONMENT})... "

  echo "Creating storage subfolder."
  for FOLDER in "app/public" \
              "framework/cache" \
              "framework/cache/data" \
              "framework/testing" \
              "framework/sessions" \
              "framework/views" \
              "logs" \
              "api-docs" \
              "keys"
  do
    runcmd "mkdir -p ${STORAGE_FOLDER}/${FOLDER}"
  done

  if [ "${ENVIRONMENT}" == "DEVELOPMENT" ]; then
    runcmd "composer install"
  fi

  runcmd "php artisan cache:clear"
  runcmd "php artisan config:clear"
  runcmd "php artisan route:clear"
  runcmd "php artisan view:clear"

  if [ "${ENVIRONMENT}" == "DEVELOPMENT" ]; then
    runcmd "php artisan package:discover --ansi"
  else
      runcmd "php artisan package:discover --ansi"
      runcmd "php artisan config:cache"
      runcmd "php artisan route:cache"
      runcmd "php artisan view:cache"
  fi
  runcmd "php artisan migrate --seed --force"
  runcmd "php artisan storage:link"
  runcmd "php artisan create-auth-keys"
  runcmd "php artisan l5-swagger:generate"

  set +e
  runcmd "chown -R www-data:www-data ${STORAGE_FOLDER}"
  set -e

  echo "Running php-fpm"
  runcmd "exec php-fpm"

elif [ "$1" == "worker" ]; then
  #
  # Worker
  #
  echo "Running Hydra-API Worker (${ENVIRONMENT})..."
  runcmd "exec php artisan queue:work --queue=height,default,low --timeout=300 -vvv
"
elif [ "$1" == "nginx" ]; then

  echo "Preparing configuration for nginx (${ENVIRONMENT})..."
  cat << EOF > /etc/nginx/conf.d/default.conf
server {
    listen 80;
    index index.php index.html;
    error_log  /var/log/nginx/error.log;
    access_log /var/log/nginx/access.log;
    root ${BASE_PATH}/public;
    location ~ \.php\$ {
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass backend:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
    }
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
        gzip_static on;
    }
}
EOF

  echo "Running nginx (${ENVIRONMENT})..."
  exec nginx -g "daemon off;"

elif [ "$1" == "cron" ]; then
    echo "Preparing environment"
    rm -f /var/log/stdout
    mkfifo /var/log/stdout
    printenv > /etc/environment
    cat << EOF > /etc/cron.d/backend
SHELL=/bin/bash
* * * * * root /bin/bash -c 'printf "\$(date) " && cd /var/www/html/laravelapp/ && /usr/local/bin/php artisan schedule:run' &> /var/log/stdout
EOF
    echo "Running cron (${ENVIRONMENT})"
    /usr/sbin/cron
    exec tail -qf /var/log/stdout
else
  exec $@
fi
