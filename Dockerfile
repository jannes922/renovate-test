# Stage 1: Builder
FROM debian:bookworm-slim AS builder

# Define the Doxygen version as an ARG to make it easier to update
ARG DOXYGEN_VERSION=1.12.0

# Install required dependencies
RUN apt-get update && apt-get install -y \
    wget \
    cmake \
    build-essential \
    python3 \
    flex \
    bison \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /tmp

# Download, extract, build, and install Doxygen using the version argument
RUN wget https://doxygen.nl/files/doxygen-${DOXYGEN_VERSION}.src.tar.gz -O doxygen.tar.gz && \
    tar -xzf doxygen.tar.gz && \
    cd doxygen-${DOXYGEN_VERSION} && \
    mkdir -p build && \
    cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=TRUE .. && \
    make -j$(nproc) && \
    make install && \
    # Clean up to reduce image size
    cd / && \
    rm -rf /tmp/doxygen-${DOXYGEN_VERSION} /tmp/doxygen.tar.gz

# Stage 2: Use a minimal base image for ARM64
FROM debian:bookworm-slim

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
# Define Doxygen version ARG here to pass to the builder stage
ARG DOXYGEN_VERSION

# Install dependencies (without unnecessary recommended packages)
RUN apt-get update && apt-get install -y --no-install-recommends \
    graphviz \
    libjs-jquery \
    libjs-mathjax \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set the default working directory
WORKDIR /docs

# Expose volume for documentation source
VOLUME /docs

# Expose output directory for generated files
VOLUME /output

# Copy the installed Doxygen binary and libraries from the builder stage
COPY --from=builder /usr/local/bin/doxygen /usr/local/bin/doxygen

# Default command to run Doxygen
CMD ["doxygen", "Doxyfile"]
