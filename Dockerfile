FROM melonc/melon
WORKDIR /root
RUN apt-get update && \
    apt-get -y install git && \
    git clone https://github.com/MelonCTech/Meproc.git
CMD /usr/bin/melang /root/Meproc/meproc.m
