#
# Docker file for DPGA Pipeline example of magasin
#
# https://unicef.github.io/magasin
#
# 
# Select the base image 
FROM python:3.10-slim

# Copy all our code into the container
COPY . /

# Install the module within the container
# This will install all the dependencies
RUN pip install .
