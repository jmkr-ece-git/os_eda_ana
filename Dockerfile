# syntax=docker/dockerfile:1

# Comments are provided throughout this file to help you get started.
# If you need more help, visit the Dockerfile reference guide at
# https://docs.docker.com/go/dockerfile-reference/

# Want to help us make this template better? Share your feedback here: https://forms.gle/ybq9Krt8jtBL3iCk7

################################################################################
# Pick a base image to serve as the foundation for the other build stages in
# this file.
#
# For illustrative purposes, the following FROM command
# is using the alpine image (see https://hub.docker.com/_/alpine).
# By specifying the "latest" tag, it will also use whatever happens to be the
# most recent version of that image when you build your Dockerfile.
# If reproducibility is important, consider using a versioned tag
# (e.g., alpine:3.17.2) or SHA (e.g., alpine@sha256:c41ab5c992deb4fe7e5da09f67a8804a46bd0592bfdf0b1847dde0e0889d2bff).
FROM ubuntu:22.04 AS base
#FROM ubuntu:20.04 as builder
################################################################################
# Create a stage for building/compiling the application.
#
# The following commands will leverage the "base" stage above to generate
# a "hello world" script and make it executable, but for a real application, you
# would issue a RUN command for your application's build process to generate the
# executable. For language-specific examples, take a look at the Dockerfiles in
# the Awesome Compose repository: https://github.com/docker/awesome-compose
FROM base AS build
ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt -y install --no-install-recommends \
    build-essential git\
    qtbase5-dev qttools5-dev \
    clang cmake libtool autoconf \
    python3 python3-dev python3-pip python3-virtualenv python3-venv \
    ruby ruby-dev \
    btop tree xterm graphviz git \
    octave liboctave-dev \
#
RUN apt update && apt -y install --no-install-recommends \
    python3-sphinx python3-sphinx-autoapi python3-pandas python3-tk python3-pytest \
    libqt5xmlpatterns5-dev qtmultimedia5-dev libqt5multimediawidgets5 libqt5svg5-dev libqt5opengl5 \
    tcl8.6 tcl-dev tcl8.6-dev \
    tk8.6 tk8.6-dev \
    flex clang gawk xdot pkg-config bison curl help2man perl time \
    libxpm4 libxpm-dev libgtk-3-dev libffi-dev \
    libjpeg-dev libfl-dev libfl2 \
    libreadline-dev gettext \
    libboost-system-dev libboost-python-dev libboost-filesystem-dev zlib1g-dev \
    libx11-6 libx11-dev \
    libxrender1 libxrender-dev \
    libxcb1 libx11-xcb-dev \
    libcairo2 libcairo2-dev libxaw7-dev \
    libgz libfl2 libfl-dev zlibc zzlib1g zlib1g-dev libz-dev libgit2-dev \
    libgoogle-perftools-dev \
    gengetopt groff pod2pdf libhpdf-dev \
    libfftw3-dev \
    libxml-libxml-perl libgd-perl \
    libsuitesparse-dev gfortran swig libspdlog-dev libeigen3-dev liblemon-dev \
    #
     ca-certificates \
    && \
    rm -rf /var/lib/apt/lists/*
#
#RUN echo -e '#!/bin/sh\n\
#echo Hello world from $(whoami)! In order to get your application running in a container, take a look at the comments in the Dockerfile to get started.'\
#> /bin/hello.sh
#RUN chmod +x /bin/hello.sh
#
################################################################################
# Create a final stage for running your application.
#
# The following commands copy the output from the "build" stage above and tell
# the container runtime to execute it when the image is run. Ideally this stage
# contains the minimal runtime dependencies for the application as to produce
# the smallest image possible. This often means using a different and smaller
# image than the one used for building the application, but for illustrative
# purposes the "base" image is used here.
FROM base AS final
#
ARG PDK_BRANCH=dev
LABEL pdk_branch=$PDK_BRANCH
#
RUN git clone --recursive https://github.com/IHP-GmbH/IHP-Open-PDK.git  \
    && cd IHP-Open-PDK \
    && git checkout $PDK_BRANCH

ENV TOOL_NAME=openvaf_23_5_0_linux_amd64
ENV OPENVAF_URL=https://openva.fra1.cdn.digitaloceanspaces.com/openvaf_23_5_0_linux_amd64.tar.gz
RUN wget $OPENVAF_URL \
    && tar -xvzf $TOOL_NAME.tar.gz -C /home/openvaf 

ENV PATH="/home/openvaf:$PATH"
ENV PATH="/home:$PATH"

RUN echo "export PDK_ROOT=\$HOME/your_directory/IHP-Open-PDK" >> ~/.bashrc
RUN echo "export PDK=ihp-sg13g2" >> ~/.bashrc
RUN echo "export KLAYOUT_PATH=\"\$HOME/.klayout:\$PDK_ROOT/\$PDK/libs.tech/klayout\"" >> ~/.bashrc
RUN echo "export KLAYOUT_HOME=\$HOME/.klayout" >> ~/.bashrc
RUN source ~/.bashrc

RUN git clone --recursive https://github.com/StefanSchippers/xschem.git xschem-src  \
    && cd IHP-Open-PDK \
    && ./configure \
    && make \
    && make install

RUN cd $PDK_ROOT/$PDK/libs.tech/xschem/ \
    && python3 install.py

RUN git clone https://git.code.sf.net/p/ngspice/ngspice ngspice-ngspice \
    && cd ngspice-ngspice \
    && ./autogen.sh \
    && ./configure --enable-osdi \
    && make \
    && sudo make install \
    && cd .. \
    && rm -rf ngspice-ngspice


    # Create a non-privileged user that the app will run under.
# See https://docs.docker.com/go/dockerfile-user-best-practices/
ARG UID=10001
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid "${UID}" \
    appuser
USER appuser
# Copy the executable from the "build" stage.
COPY --from=build /bin/hello.sh /bin/
# What the container should run when it is started.
ENTRYPOINT [ "/bin/hello.sh" ]
