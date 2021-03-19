# from rest_framework import serializers, viewsets
# from django_filters import FilterSet
# from rest_framework import permissions
# from rest_framework.permissions import IsAuthenticated

# from base.models import UsuariosRoles


# class GeneralPermission(permissions.BasePermission):

#     def has_permission(self, request, view):
#         return True


# class Filter(FilterSet):

#     class Meta:
#         model = UsuariosRoles
#         fields = {}


# class Serializer(serializers.ModelSerializer):
#     unidad_nombre = serializers.CharField(source='unidad.nombre', read_only=True)
#     rol_nombre = serializers.CharField(source='rol.nombre', read_only=True)

#     class Meta:
#         model = UsuariosRoles
#         fields = ('id',
#                   'rol',
#                   'rol_nombre',
#                   'id_usuario',
#                   'unidad_nombre',
#                   'unidad',
#                   'activo',
#                   'fuera_de_oficina',
#                   'nombre_completo',
#                   'rut',)


# class View(viewsets.ModelViewSet):
#     queryset = UsuariosRoles.objects.filter()
#     serializer_class = Serializer
#     permission_classes = [GeneralPermission]  # IsAuthenticated]
