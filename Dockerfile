FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Seoul

RUN apt-get update && \
    apt-get install -y \
      curl \
      jq \
      awscli \
      ca-certificates \
      && ln -fs /usr/share/zoneinfo/$TZ /etc/localtime \
      && dpkg-reconfigure --frontend noninteractive tzdata \
      && apt-get clean \
      && rm -rf /var/lib/apt/lists/*


WORKDIR /action
COPY entrypoint.sh /action/entrypoint.sh
RUN chmod +x /action/entrypoint.sh


ENTRYPOINT ["/action/entrypoint.sh"]
