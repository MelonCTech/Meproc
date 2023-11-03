FROM melonc/melon
WORKDIR /opt
RUN apt-get update && \
    apt-get -y install git && \
    git clone https://github.com/MelonCTech/Meproc.git
CMD /usr/bin/melang /opt/Meproc/meproc.m
