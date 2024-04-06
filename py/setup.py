from setuptools import setup
import os

if os.getenv('ROSETTABOY_USE_MYPYC', None) == '1':
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
