FROM alpine:latest

USER root
WORKDIR /

ARG KUBECTL_VERSION=1.21.0

RUN apk update && \
    apk add bash && \
    apk add jq && \
    apk add curl && \
    rm -rf /var/cache/apk/*

RUN mkdir -p /opt/kubectl && \
    cd /opt/kubectl && \
    curl --silent -LO "https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && \
    chmod 0755 /opt/kubectl/kubectl && \
    ln -s /opt/kubectl/kubectl /usr/local/bin

COPY run.sh /tmp

RUN chmod 0755 /tmp/run.sh

# what do?
CMD [ "/tmp/run.sh" ]
