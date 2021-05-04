from rest_framework import serializers, viewsets
from django_filters import FilterSet
from rest_framework import permissions
from rest_framework.permissions import IsAuthenticated

from base.models import Parametro


class GeneralPermission(permissions.BasePermission):

    def has_permission(self, request, view):
        return True


class Filter(FilterSet):

    class Meta:
        model = Parametro
        fields = {}


class Serializer(serializers.ModelSerializer):

    class Meta:
        model = Parametro
        fields = ('id',
                  'nombre',
                  'valor_parametro_char',
                  'valor_parametro_numerico'
                  )


class View(viewsets.ModelViewSet):
    queryset = Parametro.objects.filter()
    serializer_class = Serializer
    permission_classes = [GeneralPermission]  # IsAuthenticated]
