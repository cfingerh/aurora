from django.conf.urls import url
from django.urls import path
from rest_framework import routers
from usuarios.api import roles, unidades
from usuarios import views
router = routers.SimpleRouter()

# router.register(r'api/usuarios', usuarios.View)
router.register(r'api/roles', roles.View)
router.register(r'api/unidades', unidades.View)

urlpatterns = [
    path('api/usuarios/', views.usuarios),
    path('api/usuarios/<str:id_usuario>/', views.usuario),
    path('api/rolesunidades/<int:id>/', views.rolunidad),
    path('api/rolesunidades/', views.rolesunidades),
]
urlpatterns += router.urls
