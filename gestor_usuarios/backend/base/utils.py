import random
import string
from django.conf import settings

from django.contrib.auth.models import User
from base.models import UserDireccion, Direccion, Empresa


def randomString(stringLength):
    lettersAndDigits = string.ascii_letters + string.digits
    return ''.join((random.choice(lettersAndDigits) for i in range(stringLength)))


def getRoleByName(service, friendly_name):
    for i in service.roles.list():
        if i.friendly_name == friendly_name:
            return i
    return None


def getPrice(price):
    if price is None:
        return None
    if str(price) == "":
        return None
    return float(price)


def determineDataFormat(data):
    """
        Función que permite determinar el tipo de formato de datos corriendo expresiones regulares
    """
    match = re.search("^\$?(([1-9][0-9]{0,2}(\.[0-9]{3})*)|0)$", data)
    if match:
        return float(data.replace('.', '').replace(', ', '.'))
    else:
        return float(data.replace(', ', '.'))


def permisos_get_direcciones(permisos, user):
    """ Devuelve array con ids de direcciones autorizadas """

    es_superusuario = user.acceso_portal.get("superusuario", None)

    if es_superusuario:
        return Direccion.objects.all().order_by('nombre').values_list('id', flat=True)
    direcciones = user.acceso_portal.get("direcciones", None)
    return direcciones


def permisos_get_empresas(permisos, user):
    """ Devuelve array con ids de empresas autorizadas """
    es_superusuario = user.acceso_portal.get("superusuario", None)
    if es_superusuario:
        return Empresa.objects.all().order_by('nombre').values_list('id', flat=True)
    direcciones = user.acceso_portal.get("direcciones", None)
    empresas = Direccion.objects.filter(id__in=direcciones).order_by('empresa__nombre').values_list('empresa_id', flat=True)
    return empresas
    # UserPermission = User.user_permissions.through
    # ups = [up['all_direcciones'] for up in UserPermission.objects.filter(
    #     permission__codename__in=permisos, user=user).values('all_direcciones').distinct('all_direcciones')]
    # if len(ups) == 0:
    #     return []
    # if True in ups:
    #     return [d["empresa_id"] for d in Direccion.objects.all().values('empresa_id').distinct('empresa_id')]

    # return [d["direccion__empresa_id"] for d in UserDireccion.objects.filter(user=user).values('direccion__empresa_id').distinct('direccion__empresa_id')]
