FROM python:3.12
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl wget nmap netcat-openbsd dnsutils jq git tmux yosys \
    && rm -rf /var/lib/apt/lists/*
RUN pip install --no-cache-dir requests
WORKDIR /app
COPY assets/gateway.py /gateway.py
CMD ["python3", "/gateway.py"]
