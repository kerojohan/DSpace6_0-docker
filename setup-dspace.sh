#!/bin/sh

ADMIN_EMAIL="pir@csuc.cat"
ADMIN_PASSWD="csuc2016"

# creant usuari dspace
useradd -m dspace
echo "dspace:dspace"|chpasswd
chown dspace /dspace


#Baixo i Compilo el DSpace
DPSACE_TGZ_URL=https://github.com/DSpace/DSpace/archive/dspace-6.0.tar.gz
curl -L "$DPSACE_TGZ_URL" -o /tmp/dspace.tar.gz
tar -xvf /tmp/dspace.tar.gz --strip-components=1  -C /projectes/src/

 # Creant base de dades
POSTGRES_DB_HOST=${POSTGRES_DB_HOST:-localhost}
POSTGRES_DB_PORT=${POSTGRES_DB_PORT:-5432}
POSTGRES_USER=${POSTGRES_USER:-dspace}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-dspace}
POSTGRES_SCHEMA=${POSTGRES_SCHEMA:-dspace}
POSTGRES_ADMIN_USER=${POSTGRES_ADMIN_USER:-postgres}
POSTGRES_ADMIN_PASSWORD=${POSTGRES_ADMIN_PASSWORD}
DSPACE_CFG=/projectes/src/dspace/config/dspace.cfg

echo "variables db:host = ${POSTGRES_DB_HOST} db:port = ${POSTGRES_DB_PORT}"

#Si no hi ha cap dspace instal·lat farem fresh install, sinó update
if [ -d "/dspace/webapps" ]; then
	echo "dspace update"
    cd /projectes/src/ && mvn package && cd dspace/target/dspace-installer && ant update
else
   
    # Create database if not exists
SCHEMA_EXISTS=$(psql -h "$POSTGRES_DB_HOST" -p "$POSTGRES_DB_PORT" -U "$POSTGRES_ADMIN_USER" -lqt | cut -d \| -f 1 | grep -qw "$POSTGRES_SCHEMA";echo $?)
if [ $SCHEMA_EXISTS -eq 1 ]; then

 psql -h "$POSTGRES_DB_HOST" -p "$POSTGRES_DB_PORT" -d postgres -U "$POSTGRES_ADMIN_USER" -c "ALTER DATABASE ${POSTGRES_SCHEMA} SET search_path TO public,extensions;";
# Grant rights to call functions in the extensions schema to your dspace user
 psql -h "$POSTGRES_DB_HOST" -p "$POSTGRES_DB_PORT" -d postgres -U "$POSTGRES_ADMIN_USER" -c "GRANT USAGE ON SCHEMA extensions TO ${POSTGRES_SCHEMA};";
 psql -h "$POSTGRES_DB_HOST" -p "$POSTGRES_DB_PORT" -d postgres -U "$POSTGRES_ADMIN_USER" -c "CREATE DATABASE $POSTGRES_SCHEMA;" 2>&1 > /dev/null
 psql -h "$POSTGRES_DB_HOST" -p "$POSTGRES_DB_PORT" -d postgres -U "$POSTGRES_ADMIN_USER" -c "CREATE EXTENSION pgcrypto;"
  echo "Database '${POSTGRES_SCHEMA}' created"
  sleep 5s
fi

# Configure database in dspace.cfg
sed -i "s#db.url = jdbc:postgresql://localhost:5432/dspace#db.url = jdbc:postgresql://${POSTGRES_DB_HOST}:${POSTGRES_DB_PORT}/${POSTGRES_SCHEMA}#" ${DSPACE_CFG}
sed -i "s#db.username = dspace#db.username = ${POSTGRES_USER}#" ${DSPACE_CFG}
sed -i "s#db.password = dspace#db.password = ${POSTGRES_PASSWORD}#" ${DSPACE_CFG}
echo "Dspace configuration changed"

#	psql -U postgres -h 84.88.31.57 -c "CREATE USER dspace WITH LOGIN PASSWORD 'dspace'"
#	psql -U postgres -h 84.88.31.57 -c "CREATE DATABASE irta"
#	psql -U postgres -h 84.88.31.57 -c "GRANT ALL PRIVILEGES ON DATABASE irta TO dspace"

    echo "fresh_install"
    cd /projectes/src/ && mvn package && cd dspace/target/dspace-installer && ant fresh_install
    if [ -z "$ADMIN_EMAIL" ]; then
       echo "Admin email must be specified"
       exit 1
    else
       echo "Creating admin user $ADMIN_EMAIL $ADMIN_PASSWD"
       /dspace/bin/dspace create-administrator -e ${ADMIN_EMAIL} -f DSpace -l Admin -p ${ADMIN_PASSWD} -c en
    fi  
fi

