from django.contrib import admin
from django.conf.urls import include, url
from django.urls import path
from django.conf import settings
from rest_framework_simplejwt import views as jwt_views
from rest_framework.documentation import include_docs_urls


urlpatterns = [
    path('api/token/', jwt_views.TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('api/token/refresh/', jwt_views.TokenRefreshView.as_view(), name='token_refresh'),
    path('admin/', admin.site.urls),
    path('usuarios/', include('usuarios.urls')),
    path('roles/', include('roles.urls')),
    path('unidades/', include('unidades.urls')),
    path('macroprocesos/', include('macroprocesos.urls')),
    path('responsabilidades/', include('responsabilidades.urls')),
    path('procesos/', include('procesos.urls')),
    path('etapas/', include('etapas.urls')),
    path('docs/', include_docs_urls(title='My API title',
                                    authentication_classes=[],
                                    permission_classes=[]))
]

if settings.DEBUG and settings.DEBUG_TOOLBAR:
    import debug_toolbar
    urlpatterns = [
        path('__debug__/', include(debug_toolbar.urls)),

    ] + urlpatterns
