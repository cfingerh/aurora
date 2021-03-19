import sys
import os
import importlib

from django.core.wsgi import get_wsgi_application
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "conf.settings")
os.environ['DJANGO_SETTINGS_MODULE'] = 'conf.settings'
application = get_wsgi_application()

import json

# from base.utils import *
from django.contrib.auth.models import User


def ejecutar(event, context):

    with configure_scope() as scope:
        scope.set_tag("funcion", event["funcion"])

    handler_function = import_module_and_get_function(event["funcion"])
    try:
        handler_function()
    except Exception as e:
        capture_exception(e)


def import_module_and_get_function(whole_function):
    """
    Given a modular path to a function, import that module
    and return the function.
    """
    module, function = whole_function.rsplit('.', 1)
    app_module = importlib.import_module(module)
    app_function = getattr(app_module, function)
    return app_function
