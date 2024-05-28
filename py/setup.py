#!/usr/bin/env python3

from setuptools import setup, Extension
from Cython.Build import cythonize

setup(
    name="rosettaboy-pxd",
    scripts=["main.py"],
    entry_points={
        'console_scripts': [
            'rosettaboy-pxd=rbcy.main:cli_main',
        ],
    },
    ext_modules=cythonize(
        module_list=[Extension(name="*", sources=["rbcy/*.py"], libraries=["SDL2"])],
        annotate=True,
        compiler_directives={
            "language_level": 3,
            "profile": True,
            "annotation_typing": True,
        },
        include_path=["rbcy", "include"],
    )
)
