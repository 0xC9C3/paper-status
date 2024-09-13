FROM python:3.11-bookworm

WORKDIR /app

RUN git clone -b master --single-branch https://github.com/joan2937/lg lg && cd lg && make && make install

COPY requirements.txt requirements.txt

RUN apt-get update && apt-get install -yq swig && pip install -r requirements.txt

# waveshare epaper module
RUN cd /app && git clone -b master --single-branch https://github.com/waveshareteam/e-Paper.git wv && \
    mkdir -p /app/deps && mv /app/wv/RaspberryPi_JetsonNano/python /app/deps/ && pip install /app/deps/python && rm -rf /app/wv \
    && cd /app/lg/ && make && make install

COPY main.py main.py

ENTRYPOINT ["python", "main.py"]
