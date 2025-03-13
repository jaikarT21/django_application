#FROM ubuntu:latest

# Use an official Python runtime as a parent image
FROM python:3.12-slim

# Set environment variables to prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

#set a working directory
WORKDIR /app

#copy application files

COPY requirements.txt /app/
COPY devops /app/


RUN apt-get update && apt-get install -y bash && \
    python3 -m venv myenv1 && \
    /bin/bash -c "source myenv1/bin/activate && pip install --no-cache-dir -r requirements.txt"


EXPOSE 7000 



CMD ["/bin/bash" , "-c" , "source myenv1/bin/activate && python manage.py runserver 0.0.0.0:7000"]
