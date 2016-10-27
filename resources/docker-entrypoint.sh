#!/bin/bash

echo "Configure server.xml (proxy and context root)"
if [ "$(stat --format "%Y" "${CONFLUENCE_INSTALL}/conf/server.xml")" -eq "0" ]; then

  if [ -n "${ADOP_PROXYNAME}" ]; then
    xmlstarlet ed --inplace --pf --ps --insert '//Connector[@port="8090"]' --type "attr" --name "proxyName" --value "${ADOP_PROXYNAME}" "${CONFLUENCE_INSTALL}/conf/server.xml"
  fi
  if [ -n "${ADOP_PROXYPORT}" ]; then
    xmlstarlet ed --inplace --pf --ps --insert '//Connector[@port="8090"]' --type "attr" --name "proxyPort" --value "${ADOP_PROXYPORT}" "${CONFLUENCE_INSTALL}/conf/server.xml"
  fi
  if [ -n "${ADOP_PROXYSCHEME}" ]; then
    xmlstarlet ed --inplace --pf --ps --insert '//Connector[@port="8090"]' --type "attr" --name "scheme" --value "${ADOP_PROXYSCHEME}" "${CONFLUENCE_INSTALL}/conf/server.xml"
  fi
  if [ -n "${CONFLUENCE_ROOTPATH}" ]; then
    xmlstarlet ed --inplace --pf --ps --update '//Context/@path' --value "${CONFLUENCE_ROOTPATH}" "${CONFLUENCE_INSTALL}/conf/server.xml"
  fi

fi

#echo "Init confluence.cfg.xml (database)"
# If configuration is present
#if [[ -n "${DB_HOST}" && -n "${CONFLUENCE_DB}" && -n "${CONFLUENCE_DB_USER}" && -n "${CONFLUENCE_DB_PASSWORD}" ]];then
	# At the first launch
	#if [ ! -f "${CONFLUENCE_HOME}/confluence.cfg.xml" ]; then
		#mv "${CONFLUENCE_HOME}/confluence.cfg.xml.template" "${CONFLUENCE_HOME}/confluence.cfg.xml"
	#fi
	# Update values
	#xmlstarlet ed --inplace -u '/confluence-configuration/properties/property[@name="hibernate.connection.url"]' --value "jdbc:postgresql://${DB_HOST}:5432/${CONFLUENCE_DB}" "${CONFLUENCE_HOME}/confluence.cfg.xml"
	#xmlstarlet ed --inplace -u '/confluence-configuration/properties/property[@name="hibernate.connection.username"]' --value "${CONFLUENCE_DB_USER}" "${CONFLUENCE_HOME}/confluence.cfg.xml"
	#xmlstarlet ed --inplace -u '/confluence-configuration/properties/property[@name="hibernate.connection.password"]' --value "${CONFLUENCE_DB_PASSWORD}" "${CONFLUENCE_HOME}/confluence.cfg.xml"
	
#fi

echo "Checking Postgres availability ..."
until databasesList=$(PGPASSWORD="${DB_POSTGRES_PASSWORD}" psql -h "${DB_HOST}" -p "5432" -U "postgres"  -c '\l'); do
  echo "Postgres is unavailable - sleeping 1s ..."
  sleep 1
done

echo "Postgres is up !"

echo $databasesList | grep -q "${CONFLUENCE_DB}"
if [ $? -eq 0 ];then
	echo "Database ${CONFLUENCE_DB} already exists."
else
	echo "Create database ${CONFLUENCE_DB} ..."
PGPASSWORD="${DB_POSTGRES_PASSWORD}" psql -v ON_ERROR_STOP=1 --username "postgres" --host "${DB_HOST}" --port "5432" <<-EOSQL
    CREATE USER ${CONFLUENCE_DB_USER} WITH PASSWORD '${CONFLUENCE_DB_PASSWORD}';
    CREATE DATABASE ${CONFLUENCE_DB};
    GRANT ALL PRIVILEGES ON DATABASE ${CONFLUENCE_DB} TO ${CONFLUENCE_DB_USER};
EOSQL
	echo "Database ${CONFLUENCE_DB} successfully created."
fi

echo "Configuration and database setup completed successfully, starting Confluence ..."
	
# With exec, the child process replaces the parent process entirely
# exec is more precise/correct/efficient
exec $@