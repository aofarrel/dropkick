FROM python:3.11-slim
RUN apt-get update

# might be needed for gsutil to properly communicate with GCE
RUN apt-get install -y \
    ca-certificates \
    curl \
    openssl \
    gcc \
    libffi-dev

RUN apt-get install -y curl
RUN pip install --no-cache-dir gsutil

# clean up the container
RUN rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/bin/bash"]