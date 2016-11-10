#!/bin/bash



#Configurant el postgres
#/tmp/setup-postgres.sh
#sleep 5s

#Configurant el dspace
/tmp/setup-dspace.sh
sleep 5s

#Configurant el tomcat
/tmp/setup-tomcat.sh
