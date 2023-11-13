#include "@/log.m"

net = Import('net');
mq = Import('mq');
sys = Import('sys');

listenfd = net.tcp_listen(Conf['ip'], Conf['port']);
if (!listenfd) {
    Log('error', "Listen failed");
    return;
} fi

Log('info', "Meproc v1.0.0. Listen on: " + Conf['ip'] + ':' + Conf['port']);

Eval('@/http.m');

while (1) {
    fd = net.tcp_accept(listenfd);
    if (!sys.is_int(fd))
        continue;
    fi
    mq.send('accept', fd);
}
