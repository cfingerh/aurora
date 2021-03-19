from load import *
from django.contrib.auth.models import User


for user in User.objects.filter(es_cliente=True):
    modulos = None
    if user.groups.filter(pk=9).first() is None:
        modulos = ['cartola', 'documentos', 'sinader']
    if user.groups.filter(pk=23).first() is None:
        modulos = ['cartola', 'documentos', 'rga', 'sinader']

    if modulos is None:
        continue

    acceso_portal = {}
    acceso_portal["modulos"] = modulos
    if user.clientes.all().count() == 0:
        continue

    direcciones = []
    for cliente in user.clientes.all():
        for direccion in cliente.direcciones.all():
            direcciones.append(direccion.id)

    acceso_portal["direcciones"] = direcciones
    user.acceso_portal = acceso_portal
    user.save()
    print(user)
