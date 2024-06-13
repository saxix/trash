from pytest import fixture


@fixture(autouse=True, scope="session")
def django():
    import django
    from django.conf import settings
    #
    # settings.configure(
    #     # TIME_ZONE="Europe/Brussels",
    #     # USE_I18N=True,
    #     # USE_L10N=False,
    # )
    # django.setup()


@fixture(scope="function", autouse=True)
def _dj_autoclear_mailbox() -> None:
    # Override the `_dj_autoclear_mailbox` test fixture in `pytest_django`.
    pass
