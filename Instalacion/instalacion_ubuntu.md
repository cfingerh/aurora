AWS Ubuntu 20.04

Lo de la SCJ está en github (cfingerh)
Esty creando github cf@analyze.cl  c51

54.207.252.22

8080, 8180 , 9990, 389?

https://bitbucket.org/tecnova_proyectos/achn0005-fuentesgestor/src    --release/v1.0.0

https://bitbucket.org/tecnova_proyectos/achn0005-fuenteserv/src -- develop

git clone https://cfingerhuth@bitbucket.org/tecnova_proyectos/achn0005-fuentesgestor.git

t2.large con 20 GB

ssh -i ~/Documents/Claves/GestorDocumental.pem centos@52.67.34.236


La instalación se realiza en una instancia EC2 de AWS (t2.medium) con 20 GB de disco, en el sisitem operativo Ubuntu 20.04. Alfresco requier al menos 2 GB y recomienda 4 GB.



## Preparación

Se instalan una serie de librerias secundarias para facilitar la instalación. 


```
sudo apt update -y 
sudo apt upgrade -y 

sudo apt-get install openjdk-8-jdk -y

sudo apt install tmux -y
sudo apt install vim -y
sudo apt install git -y

sudo apt install unzip -y
sudo apt install mlocate -y
sudo apt install wget -y

sudo updatedb
```

En AWS EC2 se puedo obtener la IP de la máquina
```sh
URL=$(curl ifconfig.me)

```

## Postgres
Alfresco 5.1 viene con Postgres y LibreOfficec como parte de su paquete, pero sugerimos hacer una instalación de esos programa previos.

Instalación postgres y libreOffice

```sh
sudo apt install ttf-mscorefonts-installer fonts-noto fontconfig libcups2 libfontconfig1 libglu1-mesa libice6 libsm6 libxinerama1 libxrender1 libxt6 libcairo2 -y
sudo apt install libreoffice -y

sudo apt install postgresql postgresql-contrib -y
```

Crear usuarios y bases de datos alfresco y sgdp 

```sh
sudo -u postgres psql --command "CREATE USER alfresco with password 'alfresco';"
sudo -u postgres psql --command "CREATE USER sgdp with password 'gest1469';"

sudo -u postgres createdb alfresco
sudo -u postgres createdb sgdp

sudo -u postgres psql -d sgdp --command "CREATE SCHEMA sgdp AUTHORIZATION sgdp;"

sudo -u postgres psql --command "
ALTER ROLE alfresco SUPERUSER NOCREATEDB CREATEROLE INHERIT LOGIN;
ALTER ROLE sgdp SUPERUSER NOCREATEDB CREATEROLE INHERIT LOGIN;"
```

Para poder acceso a los usuarios recién creados, también es necesario modificar el archivo, 
`pg_hba.conf` modificando el tipo de autenticación a md5

```sh
sudo sed -i 's/ident/md5/g' /etc/postgresql/12/main/pg_hba.conf
sudo sed -i 's/peer/md5/g' /etc/postgresql/12/main/pg_hba.conf
sudo service postgresql restart
sudo service postgresql reload
```

Opcional para no requerir ingresar siempre las claves
```language
cd ~ 
echo "
localhost:5432:alfresco:alfresco:alfresco
localhost:5432:sgdp:sgdp:gest1469
">>.pgpass
chmod 600 .pgpass 
```

Se puede verificar que la conexión sea correcta con `psql -U alfresco -d alfresco -c '\dt'`
debiese poder logear y retornar "Did not find any relations"

## Alfresco

Para la instalación de Alfresco se descarga el software, se descoprime y se ejecuta el proceso de instalación.

Para la automatización de la instalación utilizaremos un archivo con las variables


```bash
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

```

```sh
cd ~ 
wget https://download.alfresco.com/release/community/201707-build-00028/alfresco-community-installer-201707-linux-x64.bin 
chmod a+x alfresco-community-installer-201707-linux-x64.bin 
./alfresco-community-installer-201707-linux-x64.bin --optionfile install_opts
```

```language
rm alfresco-community-installer-201707-linux-x64.bin
rm install_opts
```

La versión no automarizada es utilizando la siguiente secuencia de configuración:
(English, advnced, sin postgres ni libreoffice ni solr1)
1,2,y,n,n,n,y,y,y,y,y, enter, enter, enter, enter, alfresco, alfresco, alfresco, enter, enter, enter, enter, enter, enter,
gest1469, gest1469, yes, yes, yes, enter


## Cargas datos SGDP

El archivo datos_sgdp_inicial se encuentra en la carpeta scripts. Antes de ejecutar es necesario cambiar la IP de algunos parámetros de configuración en el archivo sql.

sed -i "s/192.168.1.92/$URL/g" ~/aurora/Instalacion/sgdp_datos_inicial.sql

psql -U sgdp -d sgdp -f ~/aurora/Instalacion/sgdp_datos_inicial.sql

El comando `psql -U sgdp -d sgdp -c '\dt'` debe devolver el lsitado de todas las tablas.


# Código fuente

El siguiente punto es descargar los códigos y configurar alfresco

```sh
cd ~ 
git clone https://cfingerhuth@bitbucket.org/tecnova_proyectos/achn0005-fuentesgestor.git
FUENTEGESTOR=/home/ubuntu/achn0005-fuentesgestor
cd $FUENTEGESTOR
git checkout develop

cd ~ 
git clone https://cfingerhuth@bitbucket.org/tecnova_proyectos/achn0005-fuenteserv.git
FUENTESERV=/home/ubuntu/achn0005-fuenteserv
cd $FUENTESERV
git checkout release/v1.0.0
```

```sh
HOME_ALFRESCO=/home/ubuntu/alfresco
$HOME_ALFRESCO/alfresco.sh stop
rm -f $HOME_ALFRESCO/alf_data/solr4/index/workspace/SpacesStore/index/*
rm -f $HOME_ALFRESCO/alf_data/solr4/index/archive/SpacesStore/index/*
rm -f $HOME_ALFRESCO/alf_data/solr4/model/*
rm -rf $HOME_ALFRESCO/alf_data/solr4/content/*

$HOME_ALFRESCO/alfresco.sh stop
cp $FUENTESERV/instalacion/amp/all-in-one-repo-amp-1.0-SNAPSHOT.amp $HOME_ALFRESCO/amps
cp $FUENTESERV/instalacion/amp/all-in-one-share-amp-1.0-SNAPSHOT.amp $HOME_ALFRESCO/amps

cd $HOME_ALFRESCO/bin
./apply_amps.sh
```
Se debe presionar enter 2 veces. Aca faltaría automatizar esto para un numanaged script de instalación.

```sh
rm -f $HOME_ALFRESCO/alf_data/solr4/index/workspace/SpacesStore/index/*
rm -f $HOME_ALFRESCO/alf_data/solr4/index/archive/SpacesStore/index/*
$HOME_ALFRESCO/alfresco.sh start
echo http://$URL:8080/solr4/admin/cores?action=FIX 
```
(No tengo claro si la url anterior es necesaria)

Detener el servicio de alfresco y ejecutar los siguientes comandos:

```sh
$HOME_ALFRESCO/alfresco.sh stop
cd $HOME_ALFRESCO/tomcat/webapps/alfresco/WEB-INF/classes/alfresco/extension/templates/webscripts/
rm -f subirCartas.post.*

cp $FUENTESERV/instalacion/xml/sgdp-carpetas.xml $HOME_ALFRESCO/tomcat/webapps/alfresco/WEB-INF/classes/alfresco/module/all-in-one-repo-amp/model/

cp $FUENTESERV/instalacion/xml/sgdp-documentos.xml $HOME_ALFRESCO/tomcat/webapps/alfresco/WEB-INF/classes/alfresco/module/all-in-one-repo-amp/model/

$HOME_ALFRESCO/alfresco.sh start

echo http://$URL:8080/alfresco/s/index
echo http://$URL:8080/share/page
```
y entrar con usuario admin y clave gest1469


(pero primero hay que hacer login) hacer un script con python?
http://$URL:8080/alfresco/s/index con post 
{reset: on,  submit: Refresh Web Scripts}


## Carpetas Permisos y Reglas

Se deben crear carpetas (completar).
También se puede ejecutar el script crear_carpetas.py, antes modificando la varfiable de la IP en ese archivo.
antes hay que desactivar CSRF

https://hub.alfresco.com/t5/alfresco-content-services-forum/disable-alfresco-csrf-cookie/td-p/202170

https://docs.alfresco.com/5.2/concepts/repository-csrf-policy.html

sed -i '44d' $HOME_ALFRESCO/tomcat/shared/classes/alfresco/web-extension/share-config-custom.xml
sed -i '40d' $HOME_ALFRESCO/tomcat/shared/classes/alfresco/web-extension/share-config-custom.xml

$HOME_ALFRESCO/alfresco.sh stop
$HOME_ALFRESCO/alfresco.sh start

(Describir proceso manual)

# Configuraciones

```sh

cp $FUENTESERV/custom-authentication-repo/custom-authentication-repo-1.0-SNAPSHOT.jar $HOME_ALFRESCO/tomcat/webapps/alfresco/WEB-INF/lib


cp $FUENTEGESTOR/alfresco/web-scripts-alfresco-sgdp/*.* $HOME_ALFRESCO/tomcat/webapps/alfresco/WEB-INF/classes/alfresco/extension/templates/webscripts/

$HOME_ALFRESCO/alfresco.sh stop
$HOME_ALFRESCO/alfresco.sh start

```

# Wildfly

```sh
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
```

```sh
#### configure systemd
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
```

Verificar con `sudo systemctl status wildfly`

```sh
cd $WILDFLY/bin
sudo sh ./add-user.sh -u administrador -p gest1469
echo http://$URL:8080
```




## LDAP

```sh
sudo apt-get install slapd ldap-utils -y
```

sudo dpkg-reconfigure slapd


con clave gest1469
app.local
dc=app
dc=local

Organziacion name: app.local

cd ~
vim ldap_data.ldif

ldapadd -x -D cn=admin,dc=app,dc=local -W -f ldap_data.ldif

### Install phpLDAPadmin on Ubuntu

```sh
sudo apt-get install ldap-account-manager -y
sudo vim /etc/apache2/conf-enabled/ldap-account-manager.conf
```

Para mayor seguiridad
In that file, look for the line `Require all granted` and replace with `Require ip 192.168.1.0/24` 

http://54.207.252.22/lam/templates/login.php

Edit Server profiles (clave inicial es lam)
 Modificar clave
 Modifcar tree sufix con "dc=app,dc=local"
 y List of avlid users 
 "cn=admin,dc=app,dc=local"

https://computingforgeeks.com/install-and-configure-ldap-account-manager-on-ubuntu/


psql -d sgdp -U sgdp --command 'INSERT INTO "SGDP_USUARIOS_ROLES" ("ID_ROL", "ID_USUARIO", "ID_UNIDAD") VALUES (3,'christian',7)'

# Wilfly

Para poder acceder a wildfly remoto (aunque mejor ocupar la consola para automatizar)
If you want to access the console from remote locations you’ll need to make small modifications to the wildfly.service, wildfly.conf and launch.sh files.


```bash
sudo sed -i '$a WILDFLY_CONSOLE_BIND=0.0.0.0' /etc/wildfly/wildfly.conf
sudo sed -i 's/-b $3/-b $3 -bmanagement $4 /g' /opt/wildfly/bin/launch.sh
sudo sed -i 's/WILDFLY_BIND/WILDFLY_BIND $WILDFLY_CONSOLE_BIND /g' /etc/systemd/system/wildfly.service

sudo mkdir /var/run/wildfly/

sudo mkdir /var/run/wildfly/
sudo chown wildfly: /var/run/wildfly/

sudo systemctl daemon-reload
sudo systemctl restart wildfly

cd ~ 
wget https://jdbc.postgresql.org/download/postgresql-42.2.18.jar
sudo bash /opt/wildfly/bin/jboss-cli.sh --connect --controller=127.0.0.1:9990 --command="deploy --force /home/ubuntu/postgresql-42.2.18.jar"

sudo bash /opt/wildfly/bin/jboss-cli.sh --connect --controller=127.0.0.1:9990 --command="data-source add --name=sgdpDS --jndi-name=java:jboss/datasources/SgdpDS --driver-name=postgresql-42.2.18.jar --connection-url=jdbc:postgresql://localhost:5432/sgdp --user-name=sgdp --password=gest1469"

sudo systemctl daemon-reload
sudo systemctl restart wildfly

```

### Crear DataSource

El objetivo es configurar un datasource a la base de datos donde está SGDP. Es importante que se debe ocupar la IP del servidor y no localhost en la configuración jdbc `jdbc:postgresql://54.207.252.22:5432/sgdp` 


### 3.6.Configuracion de aplicación web (SCJ)
#### LDAP

vim $FUENTESERV/SGDP/src/cl/gob/scj/sgdp/config/security-context.xml

```bash
sudo apt install maven -y 
cd $FUENTESERV/integracion-client-api
mvn install -Dmaven.test.skip=true
cd $FUENTESERV/SGDP
mvn clean install -Dmaven.test.skip=true

get https://jdbc.postgresql.org/download/postgresql-42.2.18.jar
sudo bash /opt/wildfly/bin/jboss-cli.sh --connect --controller=127.0.0.1:9990 --command="deploy --force /home/ubuntu/postgresql-42.2.18.jar"


```


#### Web
scp -i ~/Documents/Claves/GestorDocumental.pem ubuntu@54.207.252.22:/home/ubuntu/achn0005-fuenteserv/SGDP/target/sgdp-0.0.1-SNAPSHOT.war ~/temp/

http://$URL:8080/sgdp




slappasswd -h {SSHA} -s gest1469
ldapmodify -Y EXTERNAL -H ldapi:/// -f 1-db-setup.ldif


# Aplicación Carga Camunda (php)

sudo apt install php-pgsql -y
sudo apt-get install php libapache2-mod-php -y

sudo cp -R $FUENTESERV/sgdp-carga-subProcesos/sgdoc /var/www/html/


sudo vim /var/www/html/sgdoc/proceso/bpm/connect.php
sudo vim /var/www/html/sgdoc/proceso/bpm/logica/connect.php
sudo vim /var/www/html/sgdoc/logica/connect.php 


Modifcar el destinatario del email tambén


<!-- chown -R apache:apache /var/www/html/sgdoc/
chown -R apache:apache /var/www/html/sgdoc/
chcon -t httpd_sys_content_t /var/www/html/sgdoc/proceso/bpm/diagramas –R
chcon -t httpd_sys_r -->

sudo systemctl restart apache2
http://54.207.252.22/sgdoc/proceso/bpm/asig_user.php