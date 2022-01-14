
FROM arm32v7/debian:11.2 AS nuweb
RUN apt-get update && apt-get install -y \
  clang \
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


FROM arm32v7/debian:11.2 AS build

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

RUN apt-get update && apt-get install -y \
  file \
  unzip \
  openjdk-11-jdk-headless

RUN useradd -ms /bin/bash coleitra
USER coleitra

WORKDIR /home/coleitra
RUN wget https://dl.google.com/android/repository/commandlinetools-linux-7583922_latest.zip
RUN mkdir -p /home/coleitra/src/android-sdk/cmdline-tools
RUN unzip commandlinetools-linux-7583922_latest.zip
RUN mv cmdline-tools /home/coleitra/src/android-sdk/cmdline-tools/tools
ENV PATH="${PATH}:/home/coleitra/src/android-sdk/cmdline-tools/tools/bin"
ENV ANDROID_SDK_ROOT=/home/coleitra/src/android-sdk
RUN yes | sdkmanager "ndk;23.0.7599858"
RUN yes | sdkmanager "platform-tools"
RUN yes | sdkmanager "platforms;android-28"

WORKDIR /home/coleitra
COPY --from=nuweb --chown=coleitra:coleitra /home/coleitra/nuweb-1.61/nuweb nuweb
RUN mkdir -p \
  build/dockerfiles \
  src/scripts \
  src/unittests
COPY --chown=coleitra:coleitra doc doc


WORKDIR /home/coleitra
COPY --chown=coleitra:coleitra src src

RUN wget https://github.com/Kitware/CMake/releases/download/v3.22.1/cmake-3.22.1.tar.gz
RUN tar xfz cmake-3.22.1.tar.gz
WORKDIR /home/coleitra/cmake-3.22.1
RUN ./bootstrap
RUN make
WORKDIR /home/coleitra/doc
RUN ../nuweb -lr coleitra.w
RUN mkdir -p ../build/android
COPY --chown=coleitra:coleitra .git ../.git
WORKDIR /home/coleitra/build/android
ENV ANDROID_SDK=/home/coleitra/android-sdk
ENV ANDROID_NDK=/home/coleitra/src/android-sdk/ndk/23.0.7599858
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-armhf
RUN ../../coleitra-3.22.1/cmake -DANDROID_PLATFORM=21 \
   -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=BOTH \
   -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK/build/cmake/android.toolchain.cmake \
   ../../src
RUN make

#FROM scratch AS export
#COPY --from=build /home/coleitra/build/x64/coleitra /

CMD bash
