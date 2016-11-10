#!/bin/bash

#conf tomcat7 for dspace

if grep -q "xmlui" /usr/local/tomcat/conf/server.xml
then
    echo "configuracions fetes"
else
    a=$(cat /usr/local/tomcat/conf/server.xml | grep -n "</Host>"| cut -d : -f 1 )
	sed -i "$((a-1))r /tmp/dspace_tomcat8.conf" /usr/local/tomcat/conf/server.xml
	sleep 2s
fi


echo "ENGEGANT TOMCAT"
/usr/local/tomcat/bin/catalina.sh run
