FROM i386/alpine:edge

ENV GLIB_VERSION=2.26-6 GLIB_ARCH=i686 PYTHONUNBUFFERED=1

ADD ./config/ld.so.conf ./tmp/ld.so.conf
ADD ./webapp/requirements.txt /tmp/requirements.txt

# used for heroku ps:exec
ADD ./config/heroku-exec.sh /etc/profile.d/



RUN apk update && apk add --no-cache \
    tar \
    xz \
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
    libgcc \
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
    mkdir -p glibc-${GLIB_VERSION} /usr/glibc && \
    ln -s /bin/bash /usr/bin/bash && \
    curl -sL "http://mirror.datto.com/archlinux/pool/packages/glibc-${GLIB_VERSION}-${GLIB_ARCH}.pkg.tar.xz" -o glibc-${GLIB_VERSION}-${GLIB_ARCH}.pkg.tar.xz && \
    tar xf glibc-${GLIB_VERSION}-${GLIB_ARCH}.pkg.tar.xz -C glibc-${GLIB_VERSION} && \
    mv tmp/ld.so.conf /etc/ld.so.conf && \
    cp -a glibc-${GLIB_VERSION}/usr /usr/glibc/ && \
    glibc-${GLIB_VERSION}/usr/bin/ldconfig /usr/glibc/usr /usr/glibc/usr/lib && \
    ln -s /usr/glibc/usr/lib/ld-linux.so.2 /lib/ld-linux.so.2  && \
    rm -Rf glibc-${GLIB_VERSION} glibc-${GLIB_VERSION}-${GLIB_ARCH}.pkg.tar.xz && \ 
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
