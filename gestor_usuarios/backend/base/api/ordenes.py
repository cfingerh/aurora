from rest_framework import serializers
from rest_framework import viewsets
from django_filters import FilterSet

from base.models import OrdenTrabajo
from users.views import get_direcciones_queryset


class Filter(FilterSet):

    class Meta:
        model = OrdenTrabajo
        fields = {
            'solicitud__origen': ['exact'],
            'dia_ejecucion': ['gte', 'lte']
        }


class OrdenTrabajoSerializer(serializers.ModelSerializer):
    tipo_operacion = serializers.CharField(source='solicitud.tipo_operacion.nombre', read_only=True)
    cliente = serializers.SerializerMethodField()
    origen = serializers.SerializerMethodField()
    transporte = serializers.SerializerMethodField()
    productos = serializers.SerializerMethodField()
    destinos = serializers.SerializerMethodField()
    archivos = serializers.SerializerMethodField()
    otproductos = serializers.SerializerMethodField()

    def get_archivos(self, obj):
        return [a.get_url() for a in obj.archivos_ot.all() if a.sesma_id is None]

    def get_destinos(self, obj):
        return ", ".join([p.destino.nombre for p in obj.productos.all().distinct('destino')])

    def get_productos(self, obj):
        return ", ".join([p.producto.nombre for p in obj.productos.all()])

    def get_otproductos(self, obj):
        return [{
            'producto': p.producto.nombre,
            'pesaje_oficial': p.pesaje_oficial,
            'destino': p.destino.nombre,
        } for p in obj.productos.all()]

    def get_transporte(self, obj):
        return {'empresa': obj.empresa_transporte.nombre,
                'vehiculo': obj.vehiculo.patente if obj.vehiculo else obj.vehiculo_externo}

    def get_cliente(self, obj):
        return {'id': obj.solicitud.cliente.id,
                'nombre': obj.solicitud.cliente.nombre}

    def get_origen(self, obj):
        return {'id': obj.solicitud.origen.id,
                'nombre': obj.solicitud.origen.nombre,
                'direccion': obj.solicitud.origen.direccion
                }

    class Meta:
        model = OrdenTrabajo
        fields = ('id',
                  'solicitud',
                  'cliente',
                  'origen',
                  'tipo_operacion',
                  'archivos',
                  'transporte',
                  'destinos',
                  'dia_ejecucion',
                  'productos',
                  'otproductos'
                  )


class View(viewsets.ModelViewSet):
    queryset = OrdenTrabajo.objects.all().order_by('dia_ejecucion').select_related('solicitud__origen', 'solicitud__cliente',
                                                                                   'empresa_transporte').prefetch_related('productos__producto', 'productos__destino', 'archivos_ot')
    serializer_class = OrdenTrabajoSerializer
    filter_class = Filter

    def get_queryset(self):
        queryset = self.queryset
        queryset = queryset.filter(solicitud__origen_id__in=get_direcciones_queryset(self.request))
        queryset = queryset.filter(estado__nombre='Finalizado')
        return queryset
