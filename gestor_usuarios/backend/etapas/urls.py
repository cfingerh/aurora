from django.conf.urls import url
from django.urls import path
from rest_framework import routers
from etapas.api import etapas
router = routers.SimpleRouter()

router.register(r'api/etapas', etapas.View)

urlpatterns = [
]
urlpatterns += router.urls
