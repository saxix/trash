# -*- coding: utf-8 -*-


def test_dummy():
    from django.conf import settings
    import django
    settings.configure()
    assert settings.configured
    django.setup()