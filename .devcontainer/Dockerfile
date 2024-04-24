FROM ghcr.io/trailofbits/eth-security-toolbox:nightly

USER root
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    # For Makefiles
    make \
    # For git push/pull
    gnupg2 \
    openssh-server \
    pass \
    # For github linker
    xsel \
    # For in-terminal text editing
    vim

USER ethsec
ENV SHELL /bin/bash
