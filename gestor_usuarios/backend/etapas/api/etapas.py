from rest_framework import serializers, viewsets
from django_filters import FilterSet
from rest_framework import permissions
from rest_framework.permissions import IsAuthenticated

from base.models import Etapa


class GeneralPermission(permissions.BasePermission):

    def has_permission(self, request, view):
        return True


class Filter(FilterSet):

    class Meta:
        model = Etapa
        fields = {}


class Serializer(serializers.ModelSerializer):

    class Meta:
        model = Etapa
        fields = ('id',
                  'nombre',
                  )


class View(viewsets.ModelViewSet):
    queryset = Etapa.objects.filter()
    serializer_class = Serializer
    permission_classes = [GeneralPermission]  # IsAuthenticated]
