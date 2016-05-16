#!/bin/sh
port="$1"
shift
test -d /var/lib/manatee || mkdir /var/lib/manatee
# setup apache
a2disport http
cd /etc/httpd2/conf/
cp ports-available/http-localhost-8088.conf ports-available/"$port".conf
sed -i "s/8088/$port/g" ports-available/"$port".conf
sed -i "/^Listen/s/localhost/127.0.0.1/" ports-available/"$port".conf
a2enport "$port"
a2enmod cgi
