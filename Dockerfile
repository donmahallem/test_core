FROM docker.io/ubuntu:24.10

# Disable interactive package configuration
RUN apt-get update && \
    echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
#RUN add-apt-repository ppa:jacob/virtualisation
#RUN apt-get update && apt-get install  -y qemu qemu-user qemu-user-static
# Add a deb-src
RUN echo deb-src http://ports.ubuntu.com/ubuntu-ports \
    $(cat /etc/*release | grep VERSION_CODENAME | cut -d= -f2)  main restricted universe multiverse>> /etc/apt/sources.list 
#RUN echo deb http://archive.ubuntu.com/ubuntu \
#    jammy main universe>> /etc/apt/sources.list 

RUN apt-get update && apt-get install  -y \
    git \
    build-essential \
    autoconf \
    cmake \
    locales \
    libglu1-mesa-dev \
    libgtk-3-dev \
    libdbus-1-dev \
    libwebkit2gtk-4.1-dev \
    texinfo


RUN mkdir /PrusaSlicer && git clone https://www.github.com/prusa3d/PrusaSlicer /PrusaSlicer

ENV LC_ALL=en_US.utf8
RUN locale-gen $LC_ALL
WORKDIR /PrusaSlicer/deps

# These can run together, but we run them seperate for podman caching
# Update System dependencies
RUN mkdir build
WORKDIR /PrusaSlicer/deps/build
RUN cmake .. -DDEP_WX_GTK3=ON
RUN make

WORKDIR /PrusaSlicer
RUN mkdir build
WORKDIR /PrusaSlicer/build
RUN cmake .. -DSLIC3R_STATIC=1 -DSLIC3R_GUI=OFF -DSLIC3R_GTK=OFF -DSLIC3R_PCH=OFF -DCMAKE_PREFIX_PATH=$(pwd)/../deps/build/destdir/usr/local
RUN make

# Using an entrypoint instead of CMD because the binary
# accepts several command line arguments.
ENTRYPOINT ["/PrusaSlicer/src/prusa-slicer"]
