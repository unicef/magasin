
from setuptools import setup, find_packages
from mag import version
# Base from
# https://click.palletsprojects.com/en/8.1.x/setuptools/

setup(
    name='mag',
    version=version.get_version(),
    packages=find_packages(),
    install_requires=[
        'Click==8.1.7',
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


