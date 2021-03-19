# Servidor con los siguientes puertos abiertos 80, 5432, 8080, 8180, 22, 8983
# git clone https://github.com/cfingerh/aurora.git
# cd aurora
# git checkout instalacion
# cd ..
# URL=$(curl ifconfig.me)
# HOME_ALFRESCO=/home/ubuntu/alfresco
# FUENTEGESTOR=/home/ubuntu/aurora/fuentesgestor
# FUENTESERV=/home/ubuntu/aurora/fuenteserv


URL=$(curl ifconfig.me)
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-key C99B11DEB97541F0
sudo apt-add-repository https://cli.github.com/packages
sudo apt update
sudo apt install gh


gh auth login
mkdir ~/repositorios
cd ~/repositorios

gh repo clone cfingerh/aurora
cd aurora
git checkout instalacion
cd ..



mkdir ~/repositorios
cd ~/repositorios

gh repo clone SuperintendenciaDeCasinosCL/custom-authentication-repo
gh repo clone SuperintendenciaDeCasinosCL/FirmaAvanzada
gh repo clone SuperintendenciaDeCasinosCL/integracion-client-api
gh repo clone SuperintendenciaDeCasinosCL/num-doc-tipo-ws-rest
gh repo clone SuperintendenciaDeCasinosCL/numeracion-documentos-ws
gh repo clone SuperintendenciaDeCasinosCL/pdf-converter-net
gh repo clone SuperintendenciaDeCasinosCL/SGDP
gh repo clone SuperintendenciaDeCasinosCL/sgdp-carga-subProcesos
gh repo clone SuperintendenciaDeCasinosCL/SGDP-DOCUMENTACION
gh repo clone SuperintendenciaDeCasinosCL/sgdp-mantenedor-autores
gh repo clone SuperintendenciaDeCasinosCL/Web-Scripts-Alfresco-SGDP



###### Instalación de librerias requeridas

URL=$(curl ifconfig.me)

sudo apt update -y 
sudo apt upgrade -y 
sudo apt-get install openjdk-8-jdk -y
sudo apt install tmux -y
sudo apt install vim -y
sudo apt install git -y
sudo apt install unzip -y
sudo apt install mlocate -y
sudo apt install maven -y
sudo apt install wget -y
sudo apt install ttf-mscorefonts-installer fonts-noto fontconfig libcups2 libfontconfig1 libglu1-mesa libice6 libsm6 libxinerama1 libxrender1 libxt6 libcairo2 -y
sudo apt install libreoffice -y
sudo apt install postgresql postgresql-contrib -y
sudo updatedb

###### Crear bases de datos y usuarios

sudo -u postgres psql --command "CREATE USER alfresco with password 'alfresco';"
sudo -u postgres psql --command "CREATE USER sgdp with password 'gest1469';"
sudo -u postgres createdb alfresco
sudo -u postgres createdb sgdp
sudo -u postgres psql -d sgdp --command "CREATE SCHEMA sgdp AUTHORIZATION sgdp;"
sudo -u postgres psql --command "
ALTER ROLE alfresco SUPERUSER NOCREATEDB CREATEROLE INHERIT LOGIN;
ALTER ROLE sgdp SUPERUSER NOCREATEDB CREATEROLE INHERIT LOGIN;"

sudo sed -i 's/ident/md5/g' /etc/postgresql/12/main/pg_hba.conf
sudo sed -i 's/peer/md5/g' /etc/postgresql/12/main/pg_hba.conf
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/12/main/postgresql.conf
sudo sed -i 's/127.0.0.1\/32/0.0.0.0\/0/g' /etc/postgresql/12/main/pg_hba.conf
sudo service postgresql restart
sudo service postgresql reload

cd ~ 
echo "
localhost:5432:alfresco:alfresco:alfresco
localhost:5432:sgdp:sgdp:gest1469
">>.pgpass
chmod 600 .pgpass 


###### Modifiar datos iniciales de base de datos y cargar

cd ~
sed -i "s/192.168.1.92:8080/$URL:8080/g" ~/aurora/Instalacion/sgdp_datos_inicial.sql
psql -U sgdp -d sgdp -f ~/aurora/Instalacion/sgdp_datos_inicial.sql



# esta es solo una compilacion inicial para descargar las librerias
### Compilar  integracion-client-api
cd /home/ubuntu/repositorios/integracion-client-api
mvn install -Dmaven.test.skip=true
cp /home/ubuntu/repositorios/integracion-client-api/target/integracion-client-api-0.0.1.jar $HOME_ALFRESCO/tomcat/webapps/alfresco/WEB-INF/lib
cd ~
cd /home/ubuntu/repositorios/SGDP
mvn install -Dmaven.test.skip=true

###### Instalación de Alfresco

rm install_opts
touch install_opts
echo "
mode=unattended
enable-components=javaalfresco,alfrescosolr4,alfrescogoogledocs, libreofficecomponent
disable-components=postgres

jdbc_url=jdbc:postgresql://localhost/alfresco
jdbc_driver=org.postgresql.Driver
jdbc_database=alfresco
jdbc_username=alfresco
jdbc_password=alfresco

# Install location
prefix=/home/ubuntu/alfresco/

alfresco_admin_password=gest1469
" >> install_opts

wget https://download.alfresco.com/release/community/201707-build-00028/alfresco-community-installer-201707-linux-x64.bin 
chmod a+x alfresco-community-installer-201707-linux-x64.bin 
./alfresco-community-installer-201707-linux-x64.bin --optionfile install_opts
rm alfresco-community-installer-201707-linux-x64.bin
rm install_opts
HOME_ALFRESCO=/home/ubuntu/alfresco
$HOME_ALFRESCO/alfresco.sh start



############### Imagen #############

# http://54.207.252.22:8080/share/  -> Funciona
# echo http://$URL:8080/alfresco/s/index 


###### Configurar Alfresco

HOME_ALFRESCO=/home/ubuntu/alfresco
$HOME_ALFRESCO/alfresco.sh start

cd /home/ubuntu/repositorios/integracion-client-api
mvn install -Dmaven.test.skip=true

#UNA DE ESTAS DOS
cp /home/ubuntu/repositorios/integracion-client-api/target/integracion-client-api-0.0.1.jar $HOME_ALFRESCO/tomcat/webapps/alfresco/WEB-INF/lib

cp /home/ubuntu/repositorios/integracion-client-api/integracion-client-api-0.0.2.jar $HOME_ALFRESCO/tomcat/webapps/alfresco/WEB-INF/lib
cd ~


echo " 
authentication.chain=alfinst:alfrescoNtlm,custauth1:customauthenticator,ad1:ldap-ad
ntlm.authentication.sso.enabled=false
" >> /home/ubuntu/alfresco/tomcat/shared/classes/alfresco-global.properties
###### OJO  ######33 esto desactiva el login nomral de Alfresco ### Seguramente hacerlo mas adelante


mkdir /home/ubuntu/alfresco/tomcat/shared/classes/alfresco/extension/subsystems/
mkdir /home/ubuntu/alfresco/tomcat/shared/classes/alfresco/extension/subsystems/Authentication/
mkdir /home/ubuntu/alfresco/tomcat/shared/classes/alfresco/extension/subsystems/Authentication/ldap-ad/
mkdir /home/ubuntu/alfresco/tomcat/shared/classes/alfresco/extension/subsystems/Authentication/ldap-ad/ad1/


echo "
ldap.authentication.allowGuestLogin=false
ldap.authentication.userNameFormat=%s@lolcahost
ldap.authentication.java.naming.provider.url=ldap://localhost:389
ldap.synchronization.java.naming.security.principal=admin
ldap.synchronization.java.naming.security.credentials=gest1469
ldap.synchronization.groupSearchBase=dc\=app,dc\=local
ldap.synchronization.userSearchBase=dc\=app,dc\=local" >> /home/ubuntu/alfresco/tomcat/shared/classes/alfresco/extension/subsystems/Authentication/ldap-ad/ad1/ldap-ad-authentication.properties


# FUENTEGESTOR=/home/ubuntu/aurora/fuentesgestor
# FUENTESERV=/home/ubuntu/aurora/fuenteserv

rm -f $HOME_ALFRESCO/alf_data/solr4/index/workspace/SpacesStore/index/*
rm -f $HOME_ALFRESCO/alf_data/solr4/index/archive/SpacesStore/index/*
rm -f $HOME_ALFRESCO/alf_data/solr4/model/*
rm -rf $HOME_ALFRESCO/alf_data/solr4/content/*
cp /home/ubuntu/repositorios/SGDP-DOCUMENTACION/all-in-one-repo-amp-1.0-SNAPSHOT.amp $HOME_ALFRESCO/amps
cp /home/ubuntu/repositorios/SGDP-DOCUMENTACION/all-in-one-share-amp-1.0-SNAPSHOT.amp $HOME_ALFRESCO/amps

cd $HOME_ALFRESCO/bin
yes y | ./apply_amps.sh -force -nobackup

cp /home/ubuntu/repositorios/Web-Scripts-Alfresco-SGDP/*.* $HOME_ALFRESCO/tomcat/webapps/alfresco/WEB-INF/classes/alfresco/extension/templates/webscripts/
rm -f $HOME_ALFRESCO/alf_data/solr4/index/workspace/SpacesStore/index/*
rm -f $HOME_ALFRESCO/alf_data/solr4/index/archive/SpacesStore/index/*
echo http://$URL:8080/solr4/admin/cores?action=FIX 


cd $HOME_ALFRESCO/tomcat/webapps/alfresco/WEB-INF/classes/alfresco/extension/templates/webscripts/
rm -f subirCartas.post.*
cd ~

cp /home/ubuntu/repositorios/SGDP-DOCUMENTACION/sgdp-carpetas.xml $HOME_ALFRESCO/tomcat/webapps/alfresco/WEB-INF/classes/alfresco/module/all-in-one-repo-amp/model/
cp /home/ubuntu/repositorios/SGDP-DOCUMENTACION/sgdp-documentos.xml $HOME_ALFRESCO/tomcat/webapps/alfresco/WEB-INF/classes/alfresco/module/all-in-one-repo-amp/model/

#para descomentar parte de CSRF
sed -i '44d' $HOME_ALFRESCO/tomcat/shared/classes/alfresco/web-extension/share-config-custom.xml
sed -i '40d' $HOME_ALFRESCO/tomcat/shared/classes/alfresco/web-extension/share-config-custom.xml

$HOME_ALFRESCO/alfresco.sh stop
$HOME_ALFRESCO/alfresco.sh start


# http://54.207.252.22:8080/share/
# echo http://$URL:8080/alfresco/s/index 
# (pero primero hay que hacer login) hacer un script con python?
# http://$URL:8080/alfresco/s/index con post 
# {reset: on,  submit: Refresh Web Scripts}

echo "Pausa para cargar alfresco"
sleep 2m

URL=$(curl ifconfig.me)
export URL
cd ~ 
python3 aurora/Instalacion/crear_carpetas.py


# Wildfly

$HOME_ALFRESCO/alfresco.sh stop
cd ~ 
sudo groupadd -r wildfly
sudo useradd -r -g wildfly -d /opt/wildfly -s /sbin/nologin wildfly
wget https://download.jboss.org/wildfly/19.1.0.Final/wildfly-19.1.0.Final.zip
unzip wildfly-19.1.0.Final.zip
rm wildfly-19.1.0.Final.zip
sudo mv wildfly-19.1.0.Final /opt/
cd /opt
sudo mv wildfly-19.1.0.Final wildfly
WILDFLY=/opt/wildfly
sudo chown -RH wildfly: /opt/wildfly

sudo mkdir -p /etc/wildfly
sudo cp /opt/wildfly/docs/contrib/scripts/systemd/wildfly.conf /etc/wildfly/
sudo cp /opt/wildfly/docs/contrib/scripts/systemd/launch.sh /opt/wildfly/bin/
sudo sh -c 'chmod +x /opt/wildfly/bin/*.sh'
sudo cp /opt/wildfly/docs/contrib/scripts/systemd/wildfly.service /etc/systemd/system/
sudo chown -RH wildfly: /opt/wildfly
sudo systemctl daemon-reload
sudo systemctl stop wildfly
sudo systemctl start wildfly
sudo systemctl enable wildfly

cd $WILDFLY/bin
sudo sh ./add-user.sh -u administrador -p gest1469

sudo sed -i 's/port-offset:0/port-offset:10/g' /opt/wildfly/standalone/configuration/standalone.xml
echo http://$URL:8090
sudo systemctl stop wildfly
sudo systemctl start wildfly
sudo systemctl enable wildfly

$HOME_ALFRESCO/alfresco.sh start


# LDAP

export DEBIAN_FRONTEND=noninteractive

# echo -e " 
# slapd    slapd/internal/generated_adminpw    password   openstack
# slapd    slapd/password2    password    openstack
# slapd    slapd/internal/adminpw    password openstack
# slapd    slapd/password1    password    openstack
# " | sudo debconf-set-selections

# echo -e " 
# slapd/root_password password gest1469
# slapd/root_password_again  password gest1469
# " | sudo debconf-set-selections

sudo apt-get install -y slapd ldap-utils
###### falta headless gest1469

sudo dpkg-reconfigure slapd
#no
#app.local
#app.local
#gest1469
#gest1469
#no
#yes



cd ~
cd aurora
cd Instalacion
ldapadd -x -D cn=admin,dc=app,dc=local -f ldap_data.ldif -w gest1469

# No se si sea necesario
# sudo vim /etc/apache2/conf-enabled/ldap-account-manager.conf

sudo apt-get install ldap-account-manager -y
echo http://$URL/lam/templates/login.php

# Lam Configuration -> Edit Server Profiles -> lam / lam -> Abajo modificar password a gest1469
# TreeSufix -> dc=app,dc=local
# SecuritySettings -> cn=admin, dc=app,dc=local
# Account Typese -> LDAP suffice -> dc=app,dc=local
# Primer Crear un Group
# tuve que ir a module settings y apreta save... pq o si no aparece error
ldapwhoami -vvv -h localhost -p 389 -D 'cn=cfingerhuth,dc=app,dc=local' -x -w gest1469


#### FALTA
psql -d sgdp -U sgdp 
INSERT INTO "SGDP_USUARIOS_ROLES" ("ID_ROL", "ID_USUARIO", "ID_UNIDAD") VALUES (2,'fingerhuth',3);
update "SGDP_USUARIOS_ROLES" set "B_ACTIVO"  = true, "A_NOMBRE_COMPLETO" ='Christian Fingerhuth', "A_RUT" ='1396', "B_FUERA_DE_OFICINA" =false , "ID_USUARIO" ='fingerhuth';

# despues de modificar esto hay que compilar
sudo sed -i 's/cn=ldapadm,dc=app,dc=local/cn=admin,dc=app,dc=local/g' $FUENTESERV/SGDP/src/cl/gob/scj/sgdp/config/security-context.xml
sudo sed -i 's/Tecn2020/gest1469/g' $FUENTESERV/SGDP/src/cl/gob/scj/sgdp/config/security-context.xml

# o

<constructor-arg value="ldap://localhost/dc=app,dc=local"></constructor-arg>
<property name="userDn" value="cn=admin,dc=app,dc=local"></property>
<property name="password" value="gest1469"></property>

ldapwhoami -vvv -h localhost -p 389 -D 'cn=admin,dc=app,dc=local' -x -w gest1469


# Wildfly

sudo sed -i '$a WILDFLY_CONSOLE_BIND=0.0.0.0' /etc/wildfly/wildfly.conf
sudo sed -i 's/-b $3/-b $3 -bmanagement $4 /g' /opt/wildfly/bin/launch.sh
sudo sed -i 's/WILDFLY_BIND/WILDFLY_BIND $WILDFLY_CONSOLE_BIND /g' /etc/systemd/system/wildfly.service
sudo mkdir /var/run/wildfly/
sudo chown wildfly: /var/run/wildfly/
sudo systemctl daemon-reload
sudo systemctl restart wildfly

# Cread DS en 
# echo http://$URL:10000/console/index.html
#Administrador  gest1469
# Configuration -> Subsystems -> DataSource & Drivers -> Datasources
cd ~ 
wget https://jdbc.postgresql.org/download/postgresql-42.2.18.jar
sudo bash /opt/wildfly/bin/jboss-cli.sh --connect --controller=127.0.0.1:10000 --command="deploy --force /home/ubuntu/postgresql-42.2.18.jar"
sudo bash /opt/wildfly/bin/jboss-cli.sh --connect --controller=127.0.0.1:10000 --command="data-source add --name=sgdpDS --jndi-name=java:jboss/datasources/SgdpDS --driver-name=postgresql-42.2.18.jar --connection-url=jdbc:postgresql://localhost:5432/sgdp --user-name=sgdp --password=gest1469"
rm postgresql-42.2.18.jar

sudo systemctl daemon-reload
sudo systemctl restart wildfly

# Configurar sgdp e instalar

cd /home/ubuntu/repositorios/integracion-client-api
mvn install -Dmaven.test.skip=true

# Fix raro
vim  /home/ubuntu/repositorios/SGDP/pom.xml
y cambiar client-api a version 0.0.1

cd /home/ubuntu/repositorios/SGDP
mvn clean install -Dmaven.test.skip=true
sudo bash /opt/wildfly/bin/jboss-cli.sh --connect --controller=127.0.0.1:10000 --command="deploy --force /home/ubuntu/repositorios/SGDP/target/sgdp-0.0.1-SNAPSHOT.war "

sudo systemctl restart wildfly
echo http://$URL:8090/sgdp


# Camunda

cd ~ 
sudo apt install php-pgsql -y
sudo apt-get install php libapache2-mod-php -y

sudo cp -R $FUENTESERV/sgdp-carga-subProcesos/sgdoc /var/www/html/

sudo systemctl restart apache2
echo http://$URL/sgdoc/proceso/bpm/asig_user.php