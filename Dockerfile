FROM registry.scontain.com:5050/sconecuratedimages/apps:python-3.7.3-alpine3.10-scone5.5.0
ENV LANG C.UTF-8

RUN apk add --no-cache build-base gcc make \
    musl-dev zlib-dev bzip2-dev xz-dev libffi-dev openssl-dev \
    python3-dev py3-pynacl

COPY requirements.txt /requirements.txt
RUN pip install -r requirements.txt
 
COPY app /app

ARG CACHE_DATE=...

RUN mkdir /fspf && \
    scone fspf create /fspf/fs.fspf && \
    scone fspf addr /fspf/fs.fspf / --not-protected --kernel / && \
    scone fspf addr /fspf/fs.fspf /app --authenticated --kernel /app && \
    scone fspf addf /fspf/fs.fspf /app /app && \
    scone fspf encrypt /fspf/fs.fspf

CMD ["python3"]
