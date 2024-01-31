from setuptools import find_packages, setup

setup(
    name="dpga_pipeline",
    packages=find_packages(exclude=["dpga_pipeline_tests"]),
    install_requires=[
        "dagster",
        "dagster-cloud",
        "pandas",
        "requests"
        
    ],
    extras_require={"dev": ["dagster-webserver", "pytest"]},
)
