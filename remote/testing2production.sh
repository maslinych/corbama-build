#!/bin/sh
testport="$1"
shift
prodport="$1"
cd /etc/httpd2/conf/
cp ports-available/"$testport".conf ports-available/"$prodport".conf
sed -i "s/$testport/$prodport/g" ports-available/"$prodport".conf
a2disport "$testport"
a2enport "$prodport"
service httpd2 reload
