FROM i386/alpine:edge

ENV GLIB_VERSION=2.26-6 GLIB_ARCH=i686 PYTHONUNBUFFERED=1

ADD ./config/ld.so.conf ./tmp/ld.so.conf
ADD ./webapp/requirements.txt /tmp/requirements.txt

# used for heroku ps:exec
ADD ./config/heroku-exec.sh /etc/profile.d/



RUN apk update && apk add --no-cache \
    tar \
    procps \
    findutils \
    grep  \
    tzdata \
    python3 \   
    py3-pip \
    bash \
    curl \
    rclone \
    zlib \
    ts \
    openssh && \
    apk add --no-cache --virtual .build-dependencies \
    python3-dev \
    libevent-dev \
    gcc \
    musl-dev &&\
    pip3 install --no-cache-dir -q -r /tmp/requirements.txt && \
    apk del .build-dependencies && \
    if [[ ! -f /usr/bin/python ]]; then ln -s /usr/bin/python3 /usr/bin/python; fi && \
    mkdir -p glibc-${GLIBC_VERSION} /usr/glibc && \
    ln -s /bin/bash /usr/bin/bash && \
    curl -sL http://mirrors.aggregate.org/archlinux/core/os/${GLIB_ARCH}/glibc-${GLIB_VERSION}-${GLIB_ARCH}.pkg.tar.xz -o glibc-${GLIB_VERSION}-${GLIB_ARCH}.pkg.tar.xz && \
    tar xf glibc-${GLIB_VERSION}-${GLIB_ARCH}.pkg.tar.xz -C glibc-${GLIBC_VERSION} && \
    mv tmp/ld.so.conf /etc/ld.so.conf && \
    cp -a glibc-${GLIBC_VERSION}/usr /usr/glibc/ && \
    glibc-${GLIBC_VERSION}/usr/bin/ldconfig /usr/glibc/usr /usr/glibc/usr/lib && \
    ln -s /usr/glibc/usr/lib/ld-linux.so.2 /lib/ld-linux.so.2  && \
    rm -Rf glibc-${GLIBC_VERSION} glibc-${GLIB_VERSION}-${GLIB_ARCH}.pkg.tar.xz && \ 
    cp /lib/libc.musl-x86.so.1 /usr/lib && \
    cp /lib/libz.so.1 /usr/lib && \
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone && \
    apk del tar tzdata && \
    rm /bin/sh && ln -s /bin/bash /bin/sh


WORKDIR /app/webapp

ADD ./webapp /app/webapp/
ADD ./fanza  /app/fanza/


CMD bash start.sh