mkdir ~/repositorios
cd ~/repositorios

gh repo clone cfingerh/aurora
cd aurora
git checkout instalacion
cd ..

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



### Compilar  integracion-client-api

cd /home/ubuntu/aurora/scj/integracion-client-api
mvn install -Dmaven.test.skip=true
cp /home/ubuntu/aurora/scj/integracion-client-api/target/integracion-client-api-0.0.1.jar $HOME_ALFRESCO/tomcat/webapps/alfresco/WEB-INF/lib
cd ~

# esta es solo una compilacion inicial para descargar las librerias
cd /home/ubuntu/aurora/scj/SGDP
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