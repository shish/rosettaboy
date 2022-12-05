#!/usr/bin/env python3

from setuptools import setup
from Cython.Build import cythonize

import os

setup(
    scripts=["main.py"],
    ext_modules=cythonize(
        module_list=["src/*.py"],
        nthreads=os.cpu_count(),
        annotate=True,
        compiler_directives={
            "language_level": 3,
            "profile": True,
            "annotation_typing": True,
        },
        include_path=["src"],
    ),
)
