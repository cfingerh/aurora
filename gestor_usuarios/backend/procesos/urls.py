from django.conf.urls import url
from django.urls import path
from rest_framework import routers
from procesos.api import procesos
from procesos import views
router = routers.SimpleRouter()

router.register(r'api/procesos', procesos.View)

urlpatterns = [
    path('api/ejemplo/', views.ejemplo),
]
urlpatterns += router.urls
