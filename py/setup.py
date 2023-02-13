from setuptools import setup
import os

USE_MYPYC = False
if os.getenv('ROSETTABOY_USE_MYPYC', None) == '1':
    USE_MYPYC = True

if USE_MYPYC:
    from mypyc.build import mypycify
    packages = []
    ext_modules=mypycify(
        ['src']
    )
else:
    packages=['src']
    ext_modules = []

setup(
    name='rosettaboy',
    description='A sample Python package',
    packages=packages,
    entry_points={
        'console_scripts': [
            'rosettaboy-py=src:main.cli_main',
        ],
    },
    ext_modules=ext_modules,
)
