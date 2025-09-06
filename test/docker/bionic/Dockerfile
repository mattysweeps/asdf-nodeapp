FROM ubuntu:18.04

SHELL ["/bin/bash", "-c"]
ARG DEBIAN_FRONTEND noninteractive

# Deps required for asdf
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  ca-certificates \
  curl \
  git \
  && rm -rf /var/lib/apt

# Install system nodejs and npm
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
  && apt-get install -y --no-install-recommends \
  nodejs \
  && rm -rf /var/lib/apt

# Install jq for npm registry queries
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  jq \
  && rm -rf /var/lib/apt

ARG ASDF_BRANCH=v0.8.1
RUN git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch ${ASDF_BRANCH}

RUN echo ". $HOME/.asdf/asdf.sh" >> ~/.profile

RUN source /root/.asdf/asdf.sh && asdf plugin add nodejs
RUN source /root/.asdf/asdf.sh && asdf install nodejs 14.21.3
RUN source /root/.asdf/asdf.sh && asdf install nodejs 18.17.0

RUN source /root/.asdf/asdf.sh && asdf plugin add direnv
RUN source /root/.asdf/asdf.sh && asdf install direnv 2.28.0

# NOTE: direnv hook only works for interactive shells
RUN echo -e '#eval "$(asdf exec direnv hook bash)"\n\
  direnv() { asdf exec direnv "$@"; }\n'\
  >> ~/setup-direnv.bash

#RUN echo -e 'eval "$(asdf exec direnv export bash)"\n\
#  direnv() { asdf exec direnv "$@"; }\n'\
#  >> ~/setup-direnv.bash

## Hook direnv into your shell.
#RUN echo "eval \"\$(asdf exec direnv hook bash)\"" >> ~/.profile
## A shortcut for asdf managed direnv.
#RUN echo "eval direnv() { asdf exec direnv \"\$@\"; }" >> ~/.profile
## Make the 'use asdf' feature available:
RUN mkdir -p ~/.config/direnv && echo "source \"\$(asdf direnv hook asdf)\"" >> ~/.config/direnv/direnvrc

WORKDIR /root
COPY . asdf-nodeapp

ENTRYPOINT ["/bin/bash", "-l", "-c"]
CMD ["tail", "-f", "/dev/null"]
