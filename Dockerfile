FROM python:3.14-slim
RUN apt-get update

# might be needed for gsutil to properly communicate with GCE
RUN apt-get install -y \
    ca-certificates \
    curl \
    openssl \
    gcc \
    libffi-dev \
&& rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir gsutil

ENTRYPOINT ["/bin/bash"]
