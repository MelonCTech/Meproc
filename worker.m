#include "@/proc.m"

sys = Import('sys');
net = Import('net');
mq = Import('mq');
http = Import('http');
str = Import('str');

while (1) {
    fd = mq.recv('test');
    buf = '';
    o = nil;

    while (1) {
        ret = net.tcp_recv(fd);
        if (sys.is_bool(ret)) {
            break;
        } fi

        buf += ret;
        if (buf) {
            R = http.parse(buf);
            if (!R) {
                if (sys.is_bool(R)) {
                    break;
                } else {
                    continue;
                }
            } fi

            R['type'] = 'response';
            R['headers'] = [];
            err = false;

            uri = str.slice(R['uri'], '/');
            uri && (ctlr = str.capitalize(uri[0]), o = $ctlr);
            if (!o || sys.has(o, uri[1]) != 'method') {
                R['code'] = 404;
            } else {
                if (sys.has(o, 'acl') == 'method') {
                    if (!(sys.has(o.acl(), uri[1])) || !(o.acl()[uri[1]])) {
                        R['code'] = 404;
                        err = true;
                    } fi
                } fi
                if (!err) {
                    o.__action__ = uri[1];
                    R['body'] = o.__action__();
                } fi
            }

            net.tcp_send(fd, http.create(R));
            break;
        } fi
    }

    net.tcp_close(fd);
}
