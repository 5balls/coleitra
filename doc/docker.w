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

Docker is not required to build the application at all. It is just used here to simplify the compile process for different architectures as we have to do cross compiling at least for android.

\subsection{Documentation}

@O ../build/dockerfiles/coleitra_doc.Dockerfile
@{
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

FROM debian:11.2 AS pdf
RUN apt-get update && apt-get install -y \
  texlive-latex-recommended \
  texlive-latex-extra
RUN useradd -ms /bin/bash coleitra
USER coleitra
WORKDIR /home/coleitra
COPY --from=nuweb --chown=coleitra:coleitra /home/coleitra/nuweb-1.61/nuweb nuweb
RUN mkdir -p \
  build/dockerfiles \
  src/scripts \
  src/unittests
COPY --chown=coleitra:coleitra doc doc
WORKDIR /home/coleitra/doc
RUN ../nuweb -lr coleitra.w \
  && pdflatex coleitra.tex \
  && makeindex coleitra.idx \
  && pdflatex coleitra.tex \
  && ../nuweb -lr coleitra.w

FROM scratch AS export
COPY --from=pdf /home/coleitra/doc/coleitra.pdf /

CMD bash
@}
%USER root
%RUN apt-get update && apt-get install -y \
%  clang \
%  cmake \
%  libqt5svg5-dev \
%  qml-module-qtquick2 \
%  qml-module-qtquick-controls \
%  qml-module-qtquick-controls2 \
%  qtbase5-dev \
%  qtdeclarative5-dev
%CMD bash

\subsection{Debian binary}

The first image is for building a coleitra binary on Debian Linux. This is right now mostly a practice for me to get familiar with Docker, which I have not used before. But it could also be the start of a docker image to build debian packages, let's see.

