from django.conf.urls import url
from django.urls import path
from rest_framework import routers
from roles.api import roles
router = routers.SimpleRouter()

router.register(r'api/roles', roles.View)

urlpatterns = [
]
urlpatterns += router.urls
