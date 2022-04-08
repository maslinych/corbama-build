#!/bin/gawk -f
$0 ~ /^<doc/ { print "\n\n"; next }
#$0 ~ /^<s>/ { print "" ; next } 
$0 ~ /^<\/s/ {print txt ; txt = "" ; next }
$0 ~ /^</ { next }
$3 == "c" { txt = txt $1 ; next }
{ txt = txt " " $1 }
