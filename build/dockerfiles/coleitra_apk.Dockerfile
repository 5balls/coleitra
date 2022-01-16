
FROM debian:bullseye-slim AS nuweb
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


FROM debian:bullseye-slim AS build

RUN apt-get update && apt-get install -y \
  clang \
  cmake \
  git \
  libssl-dev \
  wget

RUN apt-get update && apt-get install -y \
  file \
  unzip \
  openjdk-11-jdk-headless \
  libstdc++6 \
  libgcc1 \
  zlib1g \
  libncurses5 \
  zutils \
  clang \
  gcc \
  g++

RUN useradd -ms /bin/bash coleitra
USER coleitra

WORKDIR /home/coleitra
RUN wget https://dl.google.com/android/repository/commandlinetools-linux-7583922_latest.zip
RUN mkdir -p /home/coleitra/src/android-sdk/cmdline-tools
RUN unzip commandlinetools-linux-7583922_latest.zip
RUN mv cmdline-tools /home/coleitra/src/android-sdk/cmdline-tools/tools
ENV PATH="${PATH}:/home/coleitra/src/android-sdk/cmdline-tools/tools/bin"
ENV ANDROID_SDK_ROOT=/home/coleitra/src/android-sdk
WORKDIR ${ANDROID_SDK_ROOT}/tools/bin
RUN yes | sdkmanager --sdk_root=${ANDROID_SDK_ROOT} --install "cmdline-tools;latest"
RUN yes | sdkmanager --sdk_root=${ANDROID_SDK_ROOT} --install "platform-tools" "platforms;android-29" "build-tools;29.0.2" "ndk;21.3.6528147" 
WORKDIR /home/coleitra
RUN wget https://download.qt.io/archive/qt/5.15/5.15.2/single/qt-everywhere-src-5.15.2.tar.xz
RUN echo "e1447db4f06c841d8947f0a6ce83a7b5  qt-everywhere-src-5.15.2.tar.xz" > md5sums.txt
RUN md5sum -c md5sums.txt
RUN tar xf qt-everywhere-src-5.15.2.tar.xz
ENV ANDROID_SDK=/home/coleitra/src/android-sdk
ENV ANDROID_NDK=/home/coleitra/src/android-sdk/ndk/21.3.6528147
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk
RUN wget https://github.com/pboettch/json-schema-validator/archive/refs/tags/2.1.0.tar.gz
RUN echo "3779dd92ff45db8b08855e2a2d7eec2c  2.1.0.tar.gz" > md5sum.txt
RUN md5sum -c md5sum.txt
RUN tar xfz 2.1.0.tar.gz
RUN mv json-schema-validator-2.1.0 src
RUN wget https://github.com/nlohmann/json/releases/download/v3.10.5/json-3.10.5.tar.xz
RUN echo "3a2f6a51df913f8d16f531844c232051  json-3.10.5.tar.xz" > md5sum.txt
RUN md5sum -c md5sum.txt
RUN mkdir -p /home/coleitra/json
RUN tar xf json-3.10.5.tar.xz -C json
RUN mv json /home/coleitra/src
RUN wget https://www.openssl.org/source/openssl-1.1.1m.tar.gz
RUN echo "8ec70f665c145c3103f6e330f538a9db  openssl-1.1.1m.tar.gz" > md5sum.txt
RUN md5sum -c md5sum.txt
RUN tar xfz openssl-1.1.1m.tar.gz
WORKDIR /home/coleitra/openssl-1.1.1m
ENV PATH="${ANDROID_NDK}/toolchains/llvm/prebuilt/linux-x86_64/bin:${ANDROID_NDK}/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/bin:${PATH}"
RUN ./Configure android-arm -D__ANDROID_API__=21
RUN make SHLIB_VERSION_NUMBER= SHLIB_EXT=_1_1.so build_libs
USER root
RUN cp libcrypto_1_1.so libssl_1_1.so /usr/local/lib
USER root
RUN mkdir build-qt
WORKDIR /home/coleitra/build-qt
RUN ../qt-everywhere-src-5.15.2/configure -xplatform android-clang -prefix /home/coleitra/qt5-android -disable-rpath -nomake tests -nomake examples -android-ndk $ANDROID_NDK -android-sdk $ANDROID_SDK -no-warnings-are-errors -openssl-runtime -optimize-size -I /home/coleitra/openssl-1.1.1m/include && gmake -j8 && gmake install
USER coleitra
WORKDIR /home/coleitra
RUN wget https://github.com/xianyi/OpenBLAS/releases/download/v0.3.17/OpenBLAS-0.3.17.tar.gz
RUN echo "5429954163bcbaccaa13e11fe30ca5b6  OpenBLAS-0.3.17.tar.gz" > md5sum.txt
RUN md5sum -c md5sum.txt
RUN tar xfz OpenBLAS-0.3.17.tar.gz
RUN cp -r OpenBLAS-0.3.17 src

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
RUN mkdir -p ../build/android
COPY --chown=coleitra:coleitra .git ../.git
WORKDIR /home/coleitra/build/android
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
RUN cmake -DANDROID_PLATFORM=21 \
   -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=BOTH \
   -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK/build/cmake/android.toolchain.cmake \
   -DCMAKE_PREFIX_PATH=/home/coleitra/qt5-android \
   ../../src
RUN make

#FROM scratch AS export
#COPY --from=build /home/coleitra/build/x64/coleitra /

CMD bash
