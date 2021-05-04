import os
import environ
import yaml
import sentry_sdk
from sentry_sdk.integrations.django import DjangoIntegration
from sentry_sdk.integrations.aws_lambda import AwsLambdaIntegration


BASE_DIR = os.path.dirname(os.path.dirname(__file__))

SECRET_KEY = 'POLOS_kv&l^gtw8u6gcukq9q%fm1ptdz#_-u-bldgk(rqa$b)Z'

root = environ.Path(__file__) - 3  # get root of the project
env = environ.Env()
environ.Env.read_env()  # reading .env file

if os.path.isfile('./variables_local.yml'):
    with open('variables_local.yml') as f:
        dataMap = yaml.safe_load(f)
        for key in dataMap.keys():
            if key not in os.environ.keys():
                os.environ[key] = str(dataMap[key])


import sentry_sdk
from sentry_sdk.integrations.django import DjangoIntegration
from sentry_sdk.integrations.aws_lambda import AwsLambdaIntegration


# if os.environ["DB_HOST"] != 'localhost':
#     sentry_sdk.init(
#         dsn="https://80c56f6249d144eba4d8c03686ae84f3@o101770.ingest.sentry.io/5619398",
#         # integrations=[DjangoIntegration(), AwsLambdaIntegration()],
#         integrations=[AwsLambdaIntegration()],
#         traces_sample_rate=1.0,
#         send_default_pii=True
#     )


DEBUG = True
TEMPLATE_DEBUG = False
DEBUG_TOOLBAR = False

DATA_UPLOAD_MAX_MEMORY_SIZE = None

ALLOWED_HOSTS = ['*']  # dy58s52fdj.execute-api.us-west-2.amazonaws.com', 'localhost', '127.0.0.1', '*']

EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'
EMAIL_HOST = 'smtp.gmail.com'
EMAIL_HOST_USER = 'informes@analyze.cl'
EMAIL_HOST_PASSWORD = 'canalyze1020'
EMAIL_PORT = 587
EMAIL_USE_TLS = True
DEFAULT_FROM_EMAIL = 'informes@analyze.cl'


DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql_psycopg2',
        'NAME': os.environ.get('DB_NAME'),
        'USER': os.environ.get('DB_USER', 'postgres'),
        'PASSWORD': os.environ.get('DB_PASSWORD'),
        'HOST': os.environ.get('DB_HOST', 'localhost'),
        'PORT': os.environ.get('DB_PORT', 5432),
        'OPTIONS': {'options': '-c search_path={}'.format(os.environ.get('DB_SCHEMA'))} if os.environ.get('DB_SCHEMA') else {},
    }
}


MIGRATION_MODULES = {
    'contenttypes': 'base.migrations.contenttypes.migrations',
    'auth': 'base.migrations.auth.migrations'
}


SITE_ROOT = os.path.dirname(os.path.realpath(__file__))

ADMINS = []


STATIC_URL = '/static/'


INSTALLED_APPS = (
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'django.contrib.humanize',
    'django.contrib.admindocs',
    'corsheaders',
    'rest_framework',
    'django_filters',
    'base',
    'usuarios',
    'procesos',
    'etapas',
    'parametros',
    'responsabilidades',


)


MIDDLEWARE = (
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',
    # 'tracking.middleware.VisitorTrackingMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
    # 'preventconcurrentlogins.middleware.PreventConcurrentLoginsMiddleware',
    # 'base.middleware.LoginRequiredMiddleware'
    # 'conf.middleware.RequestMiddleware'

)


SWAGGER_SETTINGS = {
    'USE_SESSION_AUTH': False
}


CORS_ORIGIN_ALLOW_ALL = True

if DEBUG_TOOLBAR:
    MIDDLEWARE = MIDDLEWARE + ('debug_toolbar.middleware.DebugToolbarMiddleware',)


ROOT_URLCONF = 'conf.urls'

WSGI_APPLICATION = 'conf.wsgi.application'

LOGIN_EXEMPT_URLS = (
    r'^$',
    r'^users/',
)

LANGUAGE_CODE = 'en'
TIME_ZONE = 'America/Santiago'
USE_I18N = True
USE_L10N = True
USE_TZ = False

# STATICFILES_STORAGE = 'django.contrib.staticfiles.storage.ManifestStaticFilesStorage'
STATICFILES_STORAGE = 'whitenoise.storage.CompressedStaticFilesStorage'


STATICFILES_DIRS = ()

# STATIC_ROOT = os.path.abspath(os.path.join(BASE_DIR, 'local_static'))

STATIC_ROOT = os.path.join(BASE_DIR, "local_static")
WHITENOISE_STATIC_PREFIX = '/static/'


TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': ['users/templates'],

        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]


LOGIN_URL = 'login'


LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '%(levelname)s %(asctime)s %(module)s %(process)d %(thread)d %(message)s'
        },
        'simple': {
            'format': '%(levelname)s %(message)s'
        },
    },
    'filters': {
        'require_debug_true': {
            '()': 'django.utils.log.RequireDebugTrue',
        },
    },
    'handlers': {
        'console': {
            'level': 'INFO',
            'filters': ['require_debug_true'],
            'class': 'logging.StreamHandler',
            'formatter': 'simple'
        },
        'mail_admins': {
            'level': 'ERROR',
            'class': 'django.utils.log.AdminEmailHandler',
            'include_html': True,
        }
    },
    'loggers': {
        'django': {
            'handlers': ['console'],
            'propagate': True,
        },
        'django.request': {
            'handlers': ['mail_admins'],
            'level': 'ERROR',
            'propagate': False,
        },
        'myproject.custom': {
            'handlers': ['console', 'mail_admins'],
            'level': 'INFO',
        }
    }
}

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_simplejwt.authentication.JWTAuthentication',
        # 'rest_framework.authentication.TokenAuthentication',
        'rest_framework.authentication.BasicAuthentication',
        'rest_framework.authentication.SessionAuthentication',

    ),
    'DEFAULT_PERMISSION_CLASSES': (
        'rest_framework.permissions.IsAuthenticated',
    ),
    'DEFAULT_SCHEMA_CLASS': 'rest_framework.schemas.AutoSchema',

    'DEFAULT_FILTER_BACKENDS': ('django_filters.rest_framework.DjangoFilterBackend',),
}

AUTHENTICATION_BACKENDS = (
    'django.contrib.auth.backends.ModelBackend',  # default
    # 'guardian.backends.ObjectPermissionBackend',
)

from datetime import timedelta


SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(minutes=60),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
}

INTERNAL_IPS = ['127.0.0.1']
