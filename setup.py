#!/usr/bin/env python
# -*- coding: utf-8 -*-
from setuptools import setup

TEST = ['pytest', 'isort', 'flake8']
DEV = TEST + ['check-manifest', 'twine', 'build']

setup(
    name="saxix-trash",
    version="0.1.0",
    url='',
    author='',
    author_email='',
    license='',
    description='dummy package',
    # long_description=codecs.open('README.md').read(),
    # package_dir={'': 'src'},
    # packages=find_packages(where=ROOT),
    include_package_data=True,
    tests_require=['pytest', ],
    extras_require={
        'dev': DEV,
        'test': TEST
    },
    platforms=['linux'],
    classifiers=[
        'Environment :: Web Environment',
        'Operating System :: Linux',
        'Programming Language :: Python :: 2.7',
        'Programming Language :: Python :: 3.5',
        'Intended Audience :: Developers'],
    scripts=[],
)
