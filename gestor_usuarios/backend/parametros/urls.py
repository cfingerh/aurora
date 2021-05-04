from django.conf.urls import url
from django.urls import path
from rest_framework import routers
from parametros.api import parametros
router = routers.SimpleRouter()

router.register(r'api/parametros', parametros.View)

urlpatterns = [
]
urlpatterns += router.urls
