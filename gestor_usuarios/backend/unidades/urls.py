from django.conf.urls import url
from django.urls import path
from rest_framework import routers
from unidades.api import unidades
router = routers.SimpleRouter()

router.register(r'api/unidades', unidades.View)

urlpatterns = [
]
urlpatterns += router.urls
