#include "@/log.m"

net = Import('net');
mq = Import('mq');
sys = Import('sys');

listenfd = net.tcp_listen(Conf['ip'], Conf['port']);
if (!listenfd) {
    Log('error', "Listen failed");
    return;
} fi

Log('info', "Meproc v1.0.2. Listen on: " + Conf['ip'] + ':' + Conf['port']);

Eval('@/http.m');
Eval('@/bootstrap.m', nil, false, 'bootstrap');

while (1) {
    fd = net.tcp_accept(listenfd);
    if (!sys.is_int(fd))
        continue;
    fi
    mq.send('accept', fd);
}
