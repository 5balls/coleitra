

FROM debian:11.2 AS nuweb
RUN apt-get update && apt-get install -y \
  tcc \
  wget \
  tar \
  make

RUN useradd -ms /bin/bash coleitra
USER coleitra

WORKDIR /home/coleitra
RUN wget -O nuweb.tar.gz https://sourceforge.net/projects/nuweb/files/nuweb-1.61.tar.gz/download \
  && tar xfvz nuweb.tar.gz
WORKDIR /home/coleitra/nuweb-1.61
RUN make nuweb


FROM debian:11.2 AS build

RUN apt-get update && apt-get install -y \
  clang \
  cmake \
  git \
  libssl-dev \
  wget


RUN apt-get update && apt-get install -y \
  libqt5quickcontrols2-5 \
  libqt5svg5-dev \
  qml-module-qtquick2 \
  qml-module-qtquick-controls \
  qml-module-qtquick-controls2 \
  qtbase5-dev \
  qtdeclarative5-dev \
  qtquickcontrols2-5-dev


RUN apt-get update && apt-get install -y \
  nlohmann-json3-dev
WORKDIR /root
RUN wget https://github.com/pboettch/json-schema-validator/archive/refs/tags/2.1.0.tar.gz \
  && tar xfvz 2.1.0.tar.gz
WORKDIR /root/json-schema-validator-2.1.0
RUN mkdir build
WORKDIR /root/json-schema-validator-2.1.0/build
RUN cmake ..
RUN make
RUN make install


RUN apt-get update && apt-get install -y \
  liblapack-dev


RUN useradd -ms /bin/bash coleitra
USER coleitra


WORKDIR /home/coleitra
COPY --from=nuweb --chown=coleitra:coleitra /home/coleitra/nuweb-1.61/nuweb nuweb
RUN mkdir -p \
  build/dockerfiles \
  src/scripts \
  src/unittests
COPY --chown=coleitra:coleitra doc doc


WORKDIR /home/coleitra
COPY --chown=coleitra:coleitra src src

WORKDIR /home/coleitra/doc
RUN ../nuweb -lr coleitra.w
RUN mkdir -p build/x64
WORKDIR /home/coleitra/build/x64
COPY ../../.git ../../.git
RUN cmake ../../src
RUN make

FROM scratch AS export
COPY --from=build /home/coleitra/build/x64/coleitra /

CMD bash
