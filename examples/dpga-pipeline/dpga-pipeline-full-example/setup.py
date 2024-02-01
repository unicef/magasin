from setuptools import find_packages, setup

setup(
    name="dpga_pipeline",
    packages=find_packages(exclude=["dpga_pipeline_tests"]),
    install_requires=[
        "requests",
        "minio",
        "pandas",
        "fastparquet",
        "pyarrow", 
        "dagster",
        "dagster-cloud",
        
    ],
    extras_require={"dev": ["dagster-webserver", "pytest"]},
)
