# -*- coding: utf-8 -*-


def test_wsgi():
    from trash.wsgi import application
    assert application
