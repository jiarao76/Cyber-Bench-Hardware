FROM python:3.12

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      ca-certificates curl dnsutils file git iproute2 iputils-ping \
      jq netcat-openbsd nmap procps tmux unzip vim-tiny wget \
      iverilog yosys \
    && rm -rf /var/lib/apt/lists/*

RUN python -m pip install --no-cache-dir \
      "requests>=2.32" \
      "numpy>=1.26" \
      "beautifulsoup4>=4.12"

WORKDIR /app
RUN mkdir -p /app /logs/agent /logs/verifier
