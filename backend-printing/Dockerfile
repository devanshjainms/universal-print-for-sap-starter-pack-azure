FROM mcr.microsoft.com/azure-functions/python:4-python3.10

RUN apt-get update \
    && apt-get install -y iputils-ping \
    && apt-get clean

COPY . /home/site/wwwroot

WORKDIR /home/site/wwwroot

EXPOSE 8000

RUN pip install --no-cache-dir -r requirements.txt
