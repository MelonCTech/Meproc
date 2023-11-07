#include "@/log.m"

net = Import('net');
mq = Import('mq');
sys = Import('sys');

listenfd = net.tcp_listen(Conf['ip'], Conf['port']);
if (!listenfd) {
    Log('error', "Listen failed");
    return;
} fi

Log('info', "Listen: " + Conf['ip'] + ':' + Conf['port']);

Eval('@/http.m');

while (1) {
    fd = net.tcp_accept(listenfd);
    if (!sys.is_int(fd))
        continue;
    fi
    mq.send('accept', fd);
}
