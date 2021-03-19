# -*- coding: utf-8 -*-
from django.contrib.staticfiles.testing import StaticLiveServerTestCase

# from selenium.webdriver.chrome.webdriver import WebDriver
# from selenium.webdriver.common.action_chains import ActionChains


class BaseTests(StaticLiveServerTestCase):
    # @override_settings(DEBUG=True)

    def test_inicializar(self):
        """

        """
        from pacientes.models import Prevision
        Prevision.objects.get_or_create(nombre='Cruz Blanca')

        assert True
