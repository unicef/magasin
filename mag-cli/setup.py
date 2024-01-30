
from setuptools import setup, find_packages
from mag import version
# Base from
# https://click.palletsprojects.com/en/8.1.x/setuptools/


with open("README.md") as f:
    long_description = f.read()

setup(
    name='mag',
    version=version.get_version(),
    description="Eases the tasks of managing a magasin instance. The glue between components.",
    long_description=long_description,
    long_description_content_type="text/markdown",
    author="merlos",
    url="https://github.com/unicef/magasin",
    license="MIT",
    packages=find_packages(),
    install_requires=[
        'Click==8.1.7',
        'click-aliases==1.0.4',
        'requests'
    ],
    extras_require={
        'dev': [
            'pytest',
            'coverage',
        ],
    },
    entry_points={
        'console_scripts': [
            'mag = mag.mag:cli',
        ],
    },
)


