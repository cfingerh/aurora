from django.conf.urls import url
from django.urls import path
from rest_framework import routers
from macroprocesos.api import macroprocesos
router = routers.SimpleRouter()

router.register(r'api/macroprocesos', macroprocesos.View)

urlpatterns = [
]
urlpatterns += router.urls
