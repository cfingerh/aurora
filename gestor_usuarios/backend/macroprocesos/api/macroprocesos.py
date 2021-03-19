from rest_framework import serializers, viewsets
from django_filters import FilterSet
from rest_framework import permissions
from rest_framework.permissions import IsAuthenticated

from base.models import Macroproceso


class GeneralPermission(permissions.BasePermission):

    def has_permission(self, request, view):
        return True


class Filter(FilterSet):

    class Meta:
        model = Macroproceso
        fields = {}


class Serializer(serializers.ModelSerializer):

    class Meta:
        model = Macroproceso
        fields = ('id',
                  'nombre',
                  'descripcion'
                  )


class View(viewsets.ModelViewSet):
    queryset = Macroproceso.objects.filter()
    serializer_class = Serializer
    permission_classes = [GeneralPermission]  # IsAuthenticated]
