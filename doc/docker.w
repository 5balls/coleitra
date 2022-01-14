% Copyright 2020, 2021, 2022 Florian Pesth
%
% This file is part of coleitra.
%
% coleitra is free software: you can redistribute it and/or modify
% it under the terms of the GNU Affero General Public License as
% published by the Free Software Foundation version 3 of the
% License.
%
% coleitra is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU Affero General Public License for more details.
%
% You should have received a copy of the GNU Affero General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

\section{Docker images}

Docker is not required to build the application at all. It is just used here to simplify the compile process for different architectures as we have to do cross compiling at least for android. Note that the docker files are checked in, even though they are generated. This is because we need them on github where we need to run nuweb in the container itself and therefore otherwise they would not be available.

\subsection{Scraps}
Some scraps, we use for different docker files. Docker seems clever enough to catch it for different containers.

\subsubsection{nuweb}
@d Get nuweb in docker
@{
FROM debian:11.2 AS nuweb
RUN apt-get update && apt-get install -y \
  tcc \
  wget \
  tar \
  make
@<Add and become user @'coleitra@' in docker@>
WORKDIR /home/coleitra
RUN wget -O nuweb.tar.gz https://sourceforge.net/projects/nuweb/files/nuweb-1.61.tar.gz/download \
  && tar xfvz nuweb.tar.gz
WORKDIR /home/coleitra/nuweb-1.61
RUN make nuweb
@}

\subsubsection{Debian dependencies}
Tetex makes a big docker container. It would be nice to shrink this down, maybe by using alpine.
@d Get latex dependencies for debian in docker
@{
RUN apt-get update && apt-get install -y \
  texlive-latex-recommended \
  texlive-latex-extra
@}

That said, Qt5 and compiler dependencies (not sure why) make even a bigger docker container. This stuff is all so bloated!

@d Get compiler dependencies for debian in docker
@{
RUN apt-get update && apt-get install -y \
  clang \
  cmake \
  git \
  libssl-dev \
  wget
@}

@d Get Qt5 dependencies for debian in docker
@{
RUN apt-get update && apt-get install -y \
  libqt5quickcontrols2-5 \
  libqt5svg5-dev \
  qml-module-qtquick2 \
  qml-module-qtquick-controls \
  qml-module-qtquick-controls2 \
  qtbase5-dev \
  qtdeclarative5-dev \
  qtquickcontrols2-5-dev
@}

@d Get Json dependencies for debian in docker
@{
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
@}

@d Get LAPACK dependencies for debian in docker
@{
RUN apt-get update && apt-get install -y \
  liblapack-dev
@}

\subsubsection{User}
@d Add and become user @'user@' in docker
@{
RUN useradd -ms /bin/bash @1
USER @1
@}

@d Set up documentation files for user @'user@' in docker 
@{
WORKDIR /home/@1
COPY --from=nuweb --chown=@1:@1 /home/coleitra/nuweb-1.61/nuweb nuweb
RUN mkdir -p \
  build/dockerfiles \
  src/scripts \
  src/unittests
COPY --chown=@1:@1 doc doc
@}

@d Set up source files for user @'user@' in docker 
@{
WORKDIR /home/@1
COPY --chown=@1:@1 src src
@}

\subsection{Generate developer documentation}

This container is overkill for a normal linux system but it was a good first exercise to get familiar with Docker and it is useful for github.

\lstset{language=bash}[h]
\begin{figure}
\begin{lstlisting}
DOCKER_BUILDKIT=1 docker build\
  -f build/dockerfiles/coleitra_doc.Dockerfile\
  -t coleitra_doc:$(date +%s) --output . .
\end{lstlisting}
\caption{Bash script to build docker container for creating the documentation}
\end{figure}

@O ../build/dockerfiles/coleitra_doc.Dockerfile
@{
@<Get nuweb in docker@>

FROM debian:11.2 AS pdf
@<Get latex dependencies for debian in docker @>
@<Add and become user @'coleitra@' in docker@>
@<Set up documentation files for user @'coleitra@' in docker@>
WORKDIR /home/coleitra/doc
RUN ../nuweb -lr coleitra.w \
  && pdflatex coleitra.tex \
  && makeindex coleitra.idx \
  && ../nuweb -lr coleitra.w \
  && pdflatex coleitra.tex \
  && pdflatex coleitra.tex

FROM scratch AS export
COPY --from=pdf /home/coleitra/doc/coleitra.pdf /

CMD bash
@}

\subsection{Debian binary}

This is more as a practice for the following image, the android compile.

@O ../compile_debian_binary.sh
@{
#!/bin/bash
DOCKER_BUILDKIT=1 docker build\
  -f build/dockerfiles/coleitra_debian_binary.Dockerfile\
  -t coleitra_debian_binary:latest --output . .
@}

@O ../build/dockerfiles/coleitra_debian_binary.Dockerfile
@{
@<Get nuweb in docker@>

FROM debian:11.2 AS build
@<Get compiler dependencies for debian in docker@>
@<Get Qt5 dependencies for debian in docker@>
@<Get Json dependencies for debian in docker@>
@<Get LAPACK dependencies for debian in docker@>
@<Add and become user @'coleitra@' in docker@>
@<Set up documentation files for user @'coleitra@' in docker@>
@<Set up source files for user @'coleitra@' in docker@>
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
@}

\subsection{}

@O ../create_android_apk.sh
@{
#!/bin/bash
#DOCKER_BUILDKIT=1\
#  --output .\
  docker build\
  -f build/dockerfiles/coleitra_apk.Dockerfile\
  -t coleitra_apk:latest .
@}

This docker image requires android command line tools to be downloaded already.

@O ../build/dockerfiles/coleitra_apk.Dockerfile
@{
FROM arm32v7/debian:11.2 AS nuweb
RUN apt-get update && apt-get install -y \
  clang \
  wget \
  tar \
  make
@<Add and become user @'coleitra@' in docker@>
WORKDIR /home/coleitra
RUN wget -O nuweb.tar.gz https://sourceforge.net/projects/nuweb/files/nuweb-1.61.tar.gz/download \
  && tar xfvz nuweb.tar.gz
WORKDIR /home/coleitra/nuweb-1.61
RUN make nuweb


FROM arm32v7/debian:11.2 AS build
@<Get compiler dependencies for debian in docker@>
@<Get Qt5 dependencies for debian in docker@>
@<Get Json dependencies for debian in docker@>
@<Get LAPACK dependencies for debian in docker@>
RUN apt-get update && apt-get install -y \
  file \
  unzip \
  openjdk-11-jdk-headless
@<Add and become user @'coleitra@' in docker@>
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
@<Set up documentation files for user @'coleitra@' in docker@>
@<Set up source files for user @'coleitra@' in docker@>
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
@}

@O ../create_cmake.sh
@{
#!/bin/bash
#DOCKER_BUILDKIT=1\
#  --output .\
  docker build\
  -f build/dockerfiles/coleitra_cmake.Dockerfile\
  -t coleitra_cmake:latest .
@}


@O ../build/dockerfiles/coleitra_cmake.Dockerfile
@{
FROM arm32v7/debian:11.2
@<Get compiler dependencies for debian in docker@>
@<Add and become user @'coleitra@' in docker@>
WORKDIR /home/coleitra
RUN wget https://github.com/Kitware/CMake/releases/download/v3.22.1/cmake-3.22.1.tar.gz
RUN tar xfz cmake-3.22.1.tar.gz
WORKDIR /home/coleitra/cmake-3.22.1
RUN ./bootstrap
RUN make

CMD bash
@}
