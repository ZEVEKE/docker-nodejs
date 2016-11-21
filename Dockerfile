FROM hope/base-alpine:3.4

MAINTAINER Sergey Sadovoi <sergey@hope.ua>

ENV NODEJS_VERSION=6.9.1 \
    NODE_ENV=production

RUN \
    # Install build tools
    apk add --no-cache --virtual=build-dependencies \
        curl \
        make \
        gcc \
        g++ \
        python \
        linux-headers \
        paxctl \
        gnupg && \
    apk add --no-cache \
        libgcc \
        libstdc++ && \

    cd /tmp && \

    gpg --trust-model always --keyserver pool.sks-keyservers.net --recv-keys \
        # pub   2048R/7E37093B 2015-02-03
        #       Key fingerprint = 9554 F04D 7259 F041 24DE  6B47 6D5A 82AC 7E37 093B
        # uid                  Christopher Dickinson <christopher.s.dickinson@gmail.com>
        # sub   2048R/8959D8C2 2015-02-03
        9554F04D7259F04124DE6B476D5A82AC7E37093B \

        # pub   4096R/DBE9B9C5 2015-07-21 [expires: 2019-07-21]
        #       Key fingerprint = 94AE 3667 5C46 4D64 BAFA  68DD 7434 390B DBE9 B9C5
        # uid                  Colin Ihrig <cjihrig@gmail.com>
        # sub   4096R/9B596CE2 2015-07-21 [expires: 2019-07-21]
        94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \

        # pub   4096R/D2306D93 2015-07-29 [expires: 2025-07-26]
        #       Key fingerprint = 0034 A06D 9D9B 0064 CE8A  DF6B F174 7F4A D230 6D93
        # uid                  keybase.io/octetcloud <octetcloud@keybase.io>
        # sub   4096R/CE8B0484 2015-07-29 [expires: 2025-07-26]
        0034A06D9D9B0064CE8ADF6BF1747F4AD2306D93 \

        # pub   4096R/4EB7990E 2014-04-01 [expires: 2024-03-29]
        #       Key fingerprint = FD3A 5288 F042 B685 0C66  B31F 09FE 4473 4EB7 990E
        # uid                  keybase.io/fishrock <fishrock@keybase.io>
        # sub   4096R/813DAE8E 2014-04-01 [expires: 2024-03-29]
        FD3A5288F042B6850C66B31F09FE44734EB7990E \

        # pub   4096R/7EDE3FC1 2014-11-10
        #       Key fingerprint = 71DC FD28 4A79 C3B3 8668  286B C97E C7A0 7EDE 3FC1
        # uid                  keybase.io/jasnell <jasnell@keybase.io>
        # sub   2048R/070877AC 2014-11-10 [expires: 2022-11-08]
        # sub   2048R/6100C6B1 2014-11-10 [expires: 2022-11-08]
        71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \

        # pub   2048R/7D83545D 2013-11-18
        #       Key fingerprint = DD8F 2338 BAE7 501E 3DD5  AC78 C273 792F 7D83 545D
        # uid                  Rod Vagg <rod@vagg.org>
        # uid                  Rod Vagg <r@va.gg>
        # sub   2048R/8B6AED76 2013-11-18
        DD8F2338BAE7501E3DD5AC78C273792F7D83545D \

        # pub   4096R/CC11F4C8 2016-01-12
        #       Key fingerprint = C4F0 DFFF 4E8C 1A82 3640  9D08 E73B C641 CC11 F4C8
        # uid                  Myles Borins <myles.borins@gmail.com>
        # uid                  Myles Borins <mborins@us.ibm.com>
        # sub   2048R/974031A5 2016-01-12 [expires: 2024-01-10]
        # sub   2048R/0B5CA946 2016-01-12 [expires: 2024-01-10]
        C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \

        # pub   4096R/4C206CA9 2015-12-17 [expires: 2019-12-17]
        #       Key fingerprint = B9AE 9905 FFD7 803F 2571  4661 B63B 535A 4C20 6CA9
        # uid                  Evan Lucas <evanlucas@me.com>
        # uid                  Evan Lucas <evanlucas@keybase.io>
        # sub   4096R/8D765781 2015-12-17 [expires: 2019-12-17]
        B9AE9905FFD7803F25714661B63B535A4C206CA9 && \

    # Build NodeJS
    curl -o node-v${NODEJS_VERSION}.tar.gz -sSL https://nodejs.org/dist/v${NODEJS_VERSION}/node-v${NODEJS_VERSION}.tar.gz && \
    curl -o SHASUMS256.txt.asc -sSL https://nodejs.org/dist/v${NODEJS_VERSION}/SHASUMS256.txt.asc && \
    gpg --verify SHASUMS256.txt.asc && \
    grep node-v${NODEJS_VERSION}.tar.gz SHASUMS256.txt.asc | sha256sum -c - && \
    tar -zxf node-v${NODEJS_VERSION}.tar.gz && \

    cd node-v${NODEJS_VERSION} && \
    export GYP_DEFINES="linux_use_gold_flags=0" && \
    ./configure --prefix=/usr && \
    NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) && \
    make -j${NPROC} -C out mksnapshot BUILDTYPE=Release && \
    paxctl -cm out/Release/mksnapshot && \
    make -j${NPROC} && \
    make install && \
    paxctl -cm /usr/bin/node && \

    cd /tmp && \
    if [ -x /usr/bin/npm ]; then \
        find /usr/lib/node_modules/npm -name test -o -name .bin -type d | xargs rm -rf; \
    fi && \

    # Cleanup
    apk del build-dependencies && \
    rm -rf /etc/ssl \
           /usr/share/man \
           /tmp/* \
           /var/cache/apk/* \
           /root/.npm \
           /root/.node-gyp \
           /root/.gnupg \
           /usr/lib/node_modules/npm/man \
           /usr/lib/node_modules/npm/doc \
           /usr/lib/node_modules/npm/html
