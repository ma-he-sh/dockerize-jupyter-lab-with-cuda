ARG CUDA_VERSION=12.8.0
ARG PYTHON_VERSION=3.10.12

FROM nvidia/cuda:${CUDA_VERSION}-cudnn9-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive TZ=America/Toronto

# Set NVIDIA runtime environment variables for RTX 4090/5090
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility

RUN apt-get -o Acquire::Max-FutureTime=86400 update && apt-get install -y \
    git vim curl \
    wget libgl1 libglib2.0-0 \
    openssh-server \
    python3-opencv \
    make build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
    libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev git git-lfs  \
    ffmpeg libsm6 libxext6 cmake libgl1-mesa-glx \
    && rm -rf /var/lib/apt/lists/* \
    && git lfs install

# INSTALL OPENCV
RUN apt-get update && apt-get install libopencv-dev python3-opencv -y && rm -rf /var/lib/apt/lists/*

# PREPARE WORKING DIR AND SETUP PYTHON ENV
WORKDIR /code
COPY ./requirements.txt /code/requirements.txt

RUN useradd -m -u 1000 user
USER user
ENV HOME=/home/user \
    PATH=/home/user/.local/bin:$PATH

ARG PYTHON_VERSION=3.10.12

RUN curl https://pyenv.run | bash
ENV PATH=$HOME/.pyenv/shims:$HOME/.pyenv/bin:$PATH

RUN pyenv install $PYTHON_VERSION && \
    pyenv global $PYTHON_VERSION && \
    pyenv rehash && \
    pip install --no-cache-dir --upgrade pip setuptools wheel && \
    pip install --no-cache-dir \
    datasets

VOLUME ["/src"]
WORKDIR /src

RUN pip install --upgrade pip
# Install PyTorch with CUDA 12.8 support for RTX 4090/5090
RUN pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu128
RUN pip install jupyter jupyterlab
RUN pip install pandas matplotlib tqdm scikit-learn scikit-image numpy scipy h5py tensorflow
RUN pip install opencv-contrib-python-headless

# Expose Jupyter port
EXPOSE 8888

# Start Jupyter Lab (removed --allow-root since we're running as non-root user)
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--NotebookApp.token=${JUPYTER_TOKEN:-password}"]
