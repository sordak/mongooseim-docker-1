FROM phusion/baseimage:18.04-1.0.0

ARG OTP_VSN=22.3-1

# required packages
RUN apt-get update && apt-get install -y \
    bash \
    bash-completion \
    wget \
    git \
    make \
    gcc \
    g++ \
    vim \
    bash-completion \
    libc6-dev \
    libncurses5-dev \
    libssl-dev \
    libexpat1-dev \
    libpam0g-dev \
    unixodbc-dev \
    gnupg \
    zlib1g-dev \
    wget && \
    wget https://packages.erlang-solutions.com/erlang-solutions_2.0_all.deb && \
    dpkg -i erlang-solutions_2.0_all.deb && \
    apt-get update && \
    apt-get install -y esl-erlang=1:$OTP_VSN && \
    apt-get install elixir && \
    apt-get clean

COPY ./builder/build.sh /build.sh
VOLUME /builds

CMD ["/sbin/my_init"]
