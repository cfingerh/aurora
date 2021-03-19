from django.conf.urls import url
from rest_framework import routers
# from base.api import direcciones, ordenes

router = routers.SimpleRouter()
# router.register(r'api/ordenes', ordenes.View, base_name='ordenes')

urlpatterns = [
  #  url(r'^direcciones/$', direcciones.DireccionList.as_view(), name="direcciones.DireccionList"),

]

urlpatterns += router.urls
