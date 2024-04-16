FROM ghcr.io/trailofbits/eth-security-toolbox:nightly

USER root
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    # For Makefiles
    make \
    # For git push/pull
    openssh-server \
    # For github linker
    xsel

USER ethsec
ENV SHELL /bin/bash

