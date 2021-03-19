from django.shortcuts import render
import json
from django.http import JsonResponse
import ipdb
from base.models import UsuariosRoles, Roles, Unidades
from django.views.decorators.csrf import csrf_exempt


@csrf_exempt
def rolunidad(request, id=None):
    if request.method == 'DELETE':
        usuariorol = UsuariosRoles.objects.get(pk=id)
        usuariorol.delete()

    if request.method == 'PUT':
        data = json.loads(request.body)
        usuariorol = UsuariosRoles.objects.get(pk=data.get("id"))
        usuariorol.rol_id = data.get("rol_id")
        usuariorol.unidad_id = data.get("unidad_id")
        usuariorol.activo = data.get("activo")
        usuariorol.save()

    return JsonResponse({})


@csrf_exempt
def rolesunidades(request, id=None):
    if request.method == 'POST':
        data = json.loads(request.body)
        usuariosroles = UsuariosRoles.objects.filter(id_usuario=data.get("id_usuario"))
        usuariorol = usuariosroles.first()
        usuariorol.rol_id = Roles.objects.exclude(pk__in=usuariosroles.values('rol_id')).first().id
        usuariorol.unidad_id = get_unidad_inicial()
        usuariorol.activo = False
        usuariorol.pk = None
        usuariorol.id = None
        usuariorol.save()

    return JsonResponse({})


@csrf_exempt
def usuario(request, id_usuario=None):
    if request.method == 'PUT':
        data = json.loads(request.body)
        UsuariosRoles.objects.filter(id_usuario=id_usuario).update(
            nombre_completo=data.get("nombre_completo"),
            rut=data.get("rut"),
            fuera_de_oficina=data.get("fuera_de_oficina"),
        )

        if data.get("id_usuario_para_modificar") != data.get("id_usuario"):
            UsuariosRoles.objects.filter(id_usuario=id_usuario).update(
                id_usuario=data.get("id_usuario_para_modificar")
            )

    return JsonResponse({})


def get_rol_inicial():
    return Roles.objects.all().first().id


def get_unidad_inicial():
    return Unidades.objects.all().first().id


@csrf_exempt
def usuarios(request):
    if request.method == 'POST':
        data = json.loads(request.body)
        usuario = {
            'id_usuario': data.get("id_usuario"),
            'rut': '-',
            'nombre_completo': '-',
            'rol_id': get_rol_inicial(),
            'unidad_id': get_unidad_inicial(),
            'activo': True,
            'fuera_de_oficina': False
        }
        if UsuariosRoles.objects.filter(id_usuario=data.get("id_usuario")).first() is None:
            UsuariosRoles.objects.get_or_create(**usuario)

    usuarios = list(UsuariosRoles.objects.all().order_by('id_usuario').distinct('id_usuario').values(
        'id_usuario',
        'fuera_de_oficina',
        'nombre_completo',
        'rut'))

    for usuario in usuarios:
        usuario["id_usuario_para_modificar"] = usuario["id_usuario"]
        usuario["roles"] = list(UsuariosRoles.objects.filter(id_usuario=usuario.get("id_usuario")).values(
            'id',
            'rol_id',
            'rol__nombre',
            'unidad_id',
            'unidad__nombre',
            'id_usuario',
            'activo'
        ))

    return JsonResponse(usuarios, safe=False)
