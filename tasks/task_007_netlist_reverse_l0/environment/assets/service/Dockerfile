FROM python:3.12-slim
RUN apt-get update && apt-get install -y --no-install-recommends curl     && rm -rf /var/lib/apt/lists/*
RUN pip install --no-cache-dir flask
WORKDIR /service
COPY . .
EXPOSE 5000
CMD ["python3", "server.py"]
