from django.conf.urls import url
from django.urls import path
from rest_framework import routers
from responsabilidades.api import responsabilidades
router = routers.SimpleRouter()

router.register(r'api/responsabilidades', responsabilidades.View)

urlpatterns = [
]
urlpatterns += router.urls
