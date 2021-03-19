from rest_framework import serializers, generics, viewsets

from base.models import Direccion
from django_filters import rest_framework as filters_rs

from users.views import get_direcciones_queryset


class Filter(filters_rs.FilterSet):

    class Meta:
        model = Direccion
        fields = {
        }


class DireccionSerializer(serializers.ModelSerializer):
    empresa__nombre = serializers.CharField(source='empresa.nombre', read_only=True)
    direccion = serializers.CharField(read_only=True)
    nombre = serializers.CharField(read_only=True)
    id = serializers.CharField(read_only=True)

    class Meta:
        model = Direccion
        fields = ('id',
                  'nombre',
                  'empresa__nombre',
                  'direccion',
                  )


class DireccionList(generics.ListAPIView):
    # ToDo: filtrar por usuario
    queryset = Direccion.objects.all().select_related('empresa').order_by('nombre')
    serializer_class = DireccionSerializer

    def get_queryset(self):
        return get_direcciones_queryset(self.request)
        # user = self.request.user
        # queryset = self.queryset
        # es_superusuario = user.acceso_portal.get("superusuario", None)
        # print (es_superusuario)
        # if es_superusuario:
        #     return queryset.all()

        # direcciones = user.acceso_portal.get("direcciones", None)
        # queryset = queryset.filter(id__in = direcciones)

        # return queryset
