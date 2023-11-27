ARG CUDA_VERSION=12.1.1
ARG PYTHON_VERSION=3.10.12

FROM nvidia/cuda:${CUDA_VERSION}-cudnn8-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive TZ=America/Toronto

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

# COMPILE OPENCV
WORKDIR /tmp
RUN git clone https://github.com/opencv/opencv
RUN git clone https://github.com/opencv/opencv_contrib

WORKDIR /tmp/opencv
RUN mkdir /tmp/opencv/build
WORKDIR /tmp/opencv/build

RUN cmake -D CMAKE_BUILD_TYPE=Release -D CMAKE_INSTALL_PREFIX=/usr/local -D BUILD_NEW_PYTHON_SUPPORT=ON -D WITH_V4L=ON -D INSTALL_PYTHON_EXAMPLES=ON -D OPENCV_EXTRA_MODULES_PATH=/tmp/opencv_contrib/modules ..
RUN make
RUN make install
RUN echo "/usr/local/lib" > /etc/ld.so.conf.d/opencv.conf
RUN ldconfig

WORKDIR /
RUN rm -rf /tmp/*

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

RUN pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu121
RUN pip install jupyter jupyterlab
RUN pip install pandas matplotlib tqdm scikit-learn scikit-image numpy scipy h5py tensorflow

# START THE SSH SERVER
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--allow-root"]
