#include "@/log.m"

net = Import('net');
mq = Import('mq');
sys = Import('sys');

Log('debug', "Listen: " + Conf['ip'] + ':' + Conf['port']);

listenfd = net.tcp_listen('127.0.0.1', '1234');
if (!listenfd) {
    Log('error', "Listen failed");
    return;
} fi

Eval('http.m');

while (1) {
    fd = net.tcp_accept(listenfd);
    if (!(sys.is_int(fd)))
        continue;
    fi
    mq.send('test', fd);
}
