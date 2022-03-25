# Build stage for BerkeleyDB
FROM ubuntu as berkeleydb

RUN apt-get update

RUN apt-get install -y wget
RUN apt-get install -y build-essential

ENV BERKELEYDB_VERSION=db-4.8.30.NC
ENV BERKELEYDB_PREFIX=/opt/${BERKELEYDB_VERSION}

RUN update-ca-certificates -f
RUN wget https://download.oracle.com/berkeley-db/${BERKELEYDB_VERSION}.tar.gz
RUN tar -xzf *.tar.gz
RUN sed s/__atomic_compare_exchange/__atomic_compare_exchange_db/g -i ${BERKELEYDB_VERSION}/dbinc/atomic.h
RUN mkdir -p ${BERKELEYDB_PREFIX}

WORKDIR /${BERKELEYDB_VERSION}/build_unix

RUN ../dist/configure --enable-cxx --disable-shared --with-pic --prefix=${BERKELEYDB_PREFIX}
RUN make -j`nproc`
RUN make install
RUN rm -rf ${BERKELEYDB_PREFIX}/docs

# Build stage for Redecoin Core
FROM ubuntu as redecoin-core

RUN apt-get update

RUN apt-get install -y git
RUN apt-get install -y build-essential
RUN apt-get install -y libzmq3-dev
RUN apt-get install -y autotools-dev
RUN apt-get install -y automake
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y pkg-config
RUN apt-get install -y libtool
RUN apt-get install -y libboost-all-dev
RUN apt-get install -y libssl-dev
RUN apt-get install -y libevent-dev
RUN apt-get install -y bsdmainutils
RUN apt-get install -y python3

COPY --from=berkeleydb /opt /opt

ENV REDECOIN_GIT_VERSION=v1.0.0.0
ENV REDECOIN_VERSION=1.0
ENV REDECOIN_PREFIX=/opt/redecoin-${REDECOIN_VERSION}

RUN git clone https://github.com/redecoinproject/redecoin.git /redecoin-${REDECOIN_VERSION} \
    && cd /redecoin-${REDECOIN_VERSION} \
    && git checkout ${REDECOIN_GIT_VERSION}

WORKDIR /redecoin-${REDECOIN_VERSION}

# RUN sed -i '/AC_PREREQ/a\AR_FLAGS=cr' src/univalue/configure.ac
# RUN sed -i '/AX_PROG_CC_FOR_BUILD/a\AR_FLAGS=cr' src/secp256k1/configure.ac
# RUN sed -i s:sys/fcntl.h:fcntl.h: src/compat.h
RUN ./autogen.sh

RUN ./configure LDFLAGS=-L`ls -d /opt/db*`/lib/ CPPFLAGS=-I`ls -d /opt/db*`/include/ \
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
# RUN strip ${REDECOIN_PREFIX}/lib/libredecoinconsensus.a
# RUN strip ${REDECOIN_PREFIX}/lib/libredecoinconsensus.so.0.0.0

# Build stage for compiled artifacts
FROM ubuntu

RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata
RUN apt-get install -y libzmq3-dev
RUN apt-get install -y libboost-system-dev libboost-filesystem-dev libboost-chrono-dev libboost-program-options-dev libboost-test-dev libboost-thread-dev
RUN apt-get install -y libevent-dev 
RUN apt-get install -y curl

# Install latest su-exec
RUN  set -ex; \
     \
     curl -o /usr/local/bin/su-exec.c https://raw.githubusercontent.com/ncopa/su-exec/master/su-exec.c; \
     \
     fetch_deps='gcc libc-dev'; \
     apt-get update; \
     apt-get install -y --no-install-recommends $fetch_deps; \
     rm -rf /var/lib/apt/lists/*; \
     gcc -Wall \
         /usr/local/bin/su-exec.c -o/usr/local/bin/su-exec; \
     chown root:root /usr/local/bin/su-exec; \
     chmod 0755 /usr/local/bin/su-exec; \
     rm /usr/local/bin/su-exec.c; \
     \
     apt-get purge -y --auto-remove $fetch_deps

RUN useradd -r redecoin

ENV REDECOIN_DATA=/home/redecoin/.redecoin
ENV REDECOIN_VERSION=1.0
ENV REDECOIN_PREFIX=/opt/redecoin-${REDECOIN_VERSION}
ENV PATH=${REDECOIN_PREFIX}/bin:$PATH

COPY --from=redecoin-core /opt /opt
COPY docker-entrypoint.sh /entrypoint.sh

VOLUME ["/home/redecoin/.redecoin"]

EXPOSE 23456 34567 18766 18770 

RUN ["chmod", "+x", "/entrypoint.sh"]

ENTRYPOINT ["/entrypoint.sh"]

RUN redecoind -version | grep "Redecoin Core Daemon version v${REDECOIN_VERSION}"

CMD ["redecoind"]
