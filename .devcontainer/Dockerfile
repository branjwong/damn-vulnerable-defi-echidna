FROM ghcr.io/trailofbits/eth-security-toolbox:nightly

USER root
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    make \
    openssh-server

USER ethsec
ENV SHELL /bin/bash

