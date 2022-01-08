

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
  && ../nuweb -lr coleitra.w \
  && pdflatex coleitra.tex \
  && pdflatex coleitra.tex

FROM scratch AS export
COPY --from=pdf /home/coleitra/doc/coleitra.pdf /

CMD bash
