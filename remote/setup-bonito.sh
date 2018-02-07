#!/bin/bash
corpname="$1"
corpdir="/var/www/$corpname"
shift
corplist="$@"
corpnames=($corplist)
defaultcorp="${corpnames[0]}"
for corp in ${corpnames[@]}
do
    pycorplist="$pycorplist u'$corp', "
done
# setup apache dir
cp /etc/httpd2/conf/sites-available/bonito2.conf /etc/httpd2/conf/sites-available/"$corpname".conf
sed -i "s/bonito2\?/$corpname/g" /etc/httpd2/conf/sites-available/"$corpname".conf
mkdir -p "$corpdir"
a2ensite "$corpname"
# setup bonito instance
setupbonito "$corpdir" /var/lib/manatee
cgifile="$corpdir/run.cgi"
sed -i "s/\[u'susanne'\]/[$pycorplist]/" "$cgifile"
sed -i "s/u'susanne'/u'$defaultcorp'/" "$cgifile"
sed -i "/os.environ\['MANATEE_REGISTRY'\]/s/''/'\/var\/lib\/manatee\/registry'/" "$cgifile"
