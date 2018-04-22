FROM python:alpine

WORKDIR /opt/nanoNodeWatchdog

RUN pip install --no-cache-dir requests docker

ADD nano-node-watchdog.py ./

CMD [ "python", "./nano-node-watchdog.py" ]