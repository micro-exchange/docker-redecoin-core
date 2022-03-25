# Build stage for BerkeleyDB
FROM alpine as berkeleydb

RUN sed -i 's/http\:\/\/dl-cdn.alpinelinux.org/https\:\/\/alpine.global.ssl.fastly.net/g' /etc/apk/repositories
RUN apk --no-cache add autoconf
RUN apk --no-cache add automake
RUN apk --no-cache add build-base
RUN apk --no-cache add libressl

ENV BERKELEYDB_VERSION=db-4.8.30.NC
ENV BERKELEYDB_PREFIX=/opt/${BERKELEYDB_VERSION}

RUN wget https://download.oracle.com/berkeley-db/${BERKELEYDB_VERSION}.tar.gz
RUN tar -xzf *.tar.gz
RUN sed s/__atomic_compare_exchange/__atomic_compare_exchange_db/g -i ${BERKELEYDB_VERSION}/dbinc/atomic.h
RUN mkdir -p ${BERKELEYDB_PREFIX}

WORKDIR /${BERKELEYDB_VERSION}/build_unix

RUN ../dist/configure --enable-cxx --disable-shared --with-pic --prefix=${BERKELEYDB_PREFIX}
RUN make -j`nproc`
RUN make install
RUN rm -rf ${BERKELEYDB_PREFIX}/docs

# Build stage for Boost
FROM alpine as boost

COPY --from=berkeleydb /opt /opt

RUN sed -i 's/http\:\/\/dl-cdn.alpinelinux.org/https\:\/\/alpine.global.ssl.fastly.net/g' /etc/apk/repositories
RUN apk --no-cache add openssl
RUN apk --no-cache add linux-headers
RUN apk --no-cache add build-base
RUN apk --no-cache add git

ENV BOOST_VERSION=1.64.0
ENV BOOST_PREFIX=/opt/boost-${BOOST_VERSION}

RUN wget http://downloads.sourceforge.net/project/boost/boost/${BOOST_VERSION}/boost_${BOOST_VERSION//./_}.tar.gz
RUN tar -xzf *.tar.gz
RUN mkdir -p ${BOOST_PREFIX}
RUN mv "boost_${BOOST_VERSION//./_}" /boost-${BOOST_VERSION}

WORKDIR /boost-${BOOST_VERSION}

RUN ./bootstrap.sh --prefix=${BOOST_PREFIX}
RUN ./b2 -j `nproc` install

# Build stage for Redecoin Core
FROM alpine as redecoin-core

COPY --from=boost /opt /opt

RUN sed -i 's/http\:\/\/dl-cdn.alpinelinux.org/https\:\/\/alpine.global.ssl.fastly.net/g' /etc/apk/repositories
RUN apk --no-cache add autoconf
RUN apk --no-cache add automake
RUN apk --no-cache add build-base
RUN apk --no-cache add chrpath
RUN apk --no-cache add file
RUN apk --no-cache add gnupg
RUN apk --no-cache add libevent-dev
RUN apk --no-cache add libressl
RUN apk --no-cache add libtool
RUN apk --no-cache add linux-headers
RUN apk --no-cache add zeromq-dev
RUN apk --no-cache add git
RUN apk --no-cache add openssl-dev

ENV REDECOIN_GIT_VERSION=v1.0.0.0
ENV REDECOIN_VERSION=1.0
ENV REDECOIN_PREFIX=/opt/redecoin-${REDECOIN_VERSION}

RUN git clone https://github.com/redecoinproject/redecoin.git /redecoin-${REDECOIN_VERSION} \
    && cd /redecoin-${REDECOIN_VERSION} \
    && git checkout ${REDECOIN_GIT_VERSION}

WORKDIR /redecoin-${REDECOIN_VERSION}

RUN sed -i '/AC_PREREQ/a\AR_FLAGS=cr' src/univalue/configure.ac
RUN sed -i '/AX_PROG_CC_FOR_BUILD/a\AR_FLAGS=cr' src/secp256k1/configure.ac
RUN sed -i s:sys/fcntl.h:fcntl.h: src/compat.h
RUN ./autogen.sh

# ADD ./httpserver.patch /redecoin-${REDECOIN_VERSION}/src/httpserver.patch 
# RUN cd /redecoin-${REDECOIN_VERSION}/src && patch < httpserver.patch

RUN ./configure LDFLAGS="-L`ls -d /opt/db*`/lib/ -L`ls -d /opt/boost*`/lib/" \
    CPPFLAGS="-I`ls -d /opt/db*`/include/ -I`ls -d /opt/boost*`/include/" \
    --with-boost-libdir="`ls -d /opt/boost*`/lib/" \
    --prefix=${REDECOIN_PREFIX} \
    --mandir=/usr/share/man \
    --disable-tests \
    --disable-bench \
    --disable-ccache \
    --with-gui=no \
    --with-utils \
    --with-libs \
    --with-daemon

RUN make -j`nproc`
RUN make install
RUN strip ${REDECOIN_PREFIX}/bin/redecoin-cli
# RUN strip ${REDECOIN_PREFIX}/bin/redecoin-tx
RUN strip ${REDECOIN_PREFIX}/bin/redecoind
RUN strip ${REDECOIN_PREFIX}/lib/libredecoinconsensus.a
RUN strip ${REDECOIN_PREFIX}/lib/libredecoinconsensus.so.0.0.0

# Build stage for compiled artifacts
FROM alpine

RUN adduser -S redecoin
RUN sed -i 's/http\:\/\/dl-cdn.alpinelinux.org/https\:\/\/alpine.global.ssl.fastly.net/g' /etc/apk/repositories
RUN apk --no-cache add \
  libevent \
  libzmq \
  su-exec

ENV REDECOIN_DATA=/home/redecoin/.redecoin
ENV REDECOIN_VERSION=1.0
ENV REDECOIN_PREFIX=/opt/redecoin-${REDECOIN_VERSION}
ENV BOOST_VERSION=1.64.0
ENV BOOST_PREFIX=/opt/boost-${BOOST_VERSION}
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${BOOST_PREFIX}/lib
ENV PATH=${REDECOIN_PREFIX}/bin:$PATH

COPY --from=redecoin-core /opt /opt
COPY docker-entrypoint.sh /entrypoint.sh

VOLUME ["/home/redecoin/.redecoin"]

EXPOSE 23456 34567 18766 18770 

RUN ["chmod", "+x", "/entrypoint.sh"]

ENTRYPOINT ["/entrypoint.sh"]

RUN redecoind -version | grep "Redecoin Core Daemon version v${REDECOIN_VERSION}"

CMD ["redecoind"]