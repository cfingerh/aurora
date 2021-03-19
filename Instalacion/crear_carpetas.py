# Script para crear carpetas necesarias
import requests
import os
import json

URL = 'http://{}:8080/share'.format(os.environ["URL"])

ses = requests.session()
ses.get(URL+'/page')

logindata={
    'success': '/share/page/',
'failure': '/share/page/?error=true',
'username': 'admin',
'password': 'gest1469',}

resp=ses.post("{}/page/dologin".format(URL), data=logindata)

# Obtener SpaceStore raiz

resp = ses.get(URL+'/service/components/documentlibrary/data/doclist/all/node/alfresco/user/home/?filter=path&size=50&pos=1&sortAsc=true&sortField=cm%3Aname&libraryRoot=alfresco%3A%2F%2Fcompany%2Fhome&view=browse')
ws = json.loads(resp.text).get("metadata").get("container")

# Crear carpeta

url_crear_carpeta = URL+'/proxy/alfresco/api/type/cm%3Afolder/formprocessor'
data =  {
    "alf_destination":ws,
    "prop_cm_name":"SCJ_WORKSPACE",
    "prop_cm_title":"",
    "prop_cm_description":""}
resp = ses.post(url_crear_carpeta, json=data)

scj_ws= json.loads(resp.text).get("persistedObject")

# Permisos
url = '{}/proxy/alfresco/slingshot/doclib/permissions/workspace/SpacesStore/{}'.format(URL, scj_ws.split("/")[-1])
data = {
    "permissions":
[{"authority":"GROUP_EVERYONE","role":"Collaborator"}],
"isInherited":False
}

data =  {
    "alf_destination":scj_ws,
    "prop_cm_name":"ARCHIVOS_TEMPORALES",
    "prop_cm_title":"",
    "prop_cm_description":""}
resp = ses.post(url_crear_carpeta, json=data)
data =  {
    "alf_destination":scj_ws,
    "prop_cm_name":"OPARTES",
    "prop_cm_title":"",
    "prop_cm_description":""}
resp = ses.post(url_crear_carpeta, json=data)


data =  {
    "alf_destination":ws,
    "prop_cm_name":"Codigos_QR",
    "prop_cm_title":"",
    "prop_cm_description":""}
resp = ses.post(url_crear_carpeta, json=data)
data =  {
    "alf_destination":ws,
    "prop_cm_name":"Imagenes",
    "prop_cm_title":"",
    "prop_cm_description":""}
resp = ses.post(url_crear_carpeta, json=data)