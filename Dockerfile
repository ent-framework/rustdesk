FROM debian:bullseye-slim

#ENV http_proxy=http://10.10.174.138:8118
#ENV https_proxy=http://10.10.174.138:8118

WORKDIR /
ARG DEBIAN_FRONTEND=noninteractive
ENV VCPKG_FORCE_SYSTEM_BINARIES=1

RUN sed -i "s|deb.debian.org|mirrors.aliyun.com|g" /etc/apt/sources.list && \
    sed -i "s|security.debian.org|mirrors.aliyun.com|g" /etc/apt/sources.list

RUN apt update -y && \
    apt install --yes --no-install-recommends \
        g++ \
        gcc \
        git \
        curl \
        nasm \
        yasm \
        libgtk-3-dev \
        clang \
        libxcb-randr0-dev \
        libxdo-dev \
        libxfixes-dev \
        libxcb-shape0-dev \
        libxcb-xfixes0-dev \
        libasound2-dev \
        libpam0g-dev \
        libpulse-dev \
        make \
        wget \
        libssl-dev \
        unzip \
        zip \
        sudo \
        libgstreamer1.0-dev \
        libgstreamer-plugins-base1.0-dev \
        ca-certificates \
        ninja-build && \
        rm -rf /var/lib/apt/lists/*

RUN git config --global http.proxy http://10.10.174.138:8118
RUN git config --global https.proxy http://10.10.174.138:8118

#RUN wget https://github.com/Kitware/CMake/releases/download/v3.30.6/cmake-3.30.6.tar.gz --no-check-certificate && \
COPY ./tmp/cmake-3.30.6.tar.gz .

RUN tar xzf cmake-3.30.6.tar.gz && \
    cd cmake-3.30.6 && \
    ./configure  --prefix=/usr/local && \
    make && \
    make install

COPY ./tmp/vcpkg /vcpkg

#RUN git clone --branch 2023.04.15 --depth=1 https://github.com/microsoft/vcpkg && \
RUN  /vcpkg/bootstrap-vcpkg.sh -disableMetrics && \
    /vcpkg/vcpkg --disable-metrics install libvpx libyuv opus aom

RUN groupadd -r user && \
    useradd -r -g user user --home /home/user && \
    mkdir -p /home/user/rustdesk && \
    chown -R user: /home/user && \
    echo "user ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/user

WORKDIR /home/user
# RUN curl -LO https://raw.githubusercontent.com/c-smile/sciter-sdk/master/bin.lnx/x64/libsciter-gtk.so
COPY ./tmp/libsciter-gtk.so .

USER user
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > rustup.sh && \
    chmod +x rustup.sh && \
    ./rustup.sh -y

#RUN echo '[source.crates-io]' > ~/.cargo/config \
# && echo 'registry = "https://github.com/rust-lang/crates.io-index"'  >> ~/.cargo/config \
# && echo '# 替换成你偏好的镜像源'  >> ~/.cargo/config \
# && echo "replace-with = 'sjtu'"  >> ~/.cargo/config \
# && echo '# 上海交通大学'   >> ~/.cargo/config \
# && echo '[source.sjtu]'   >> ~/.cargo/config \
# && echo 'registry = "https://mirrors.sjtug.sjtu.edu.cn/git/crates.io-index"'  >> ~/.cargo/config \
# && echo '' >> ~/.cargo/config

USER root
ENV HOME=/home/user
COPY ./entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
