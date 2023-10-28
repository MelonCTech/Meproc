#include "@/proc.m"

sys = Import('sys');
net = Import('net');
mq = Import('mq');
http = Import('http');
str = Import('str');

while (1) {
    data = mq.recv('http', 1000);
    if (!(sys.is_nil(data))) {
        Programs[data] && --(Programs[data]['running']);
    } fi

    if (!timeout) {
        fd = mq.recv('accept', 1000);
        if (sys.is_nil(fd))
            continue;
        fi
        buf = '';
        o = nil;
        timeout = false;
    } fi

    while (1) {
        ret = net.tcp_recv(fd, 1);
        if (sys.is_bool(ret)) {
            timeout = false;
            break;
        } else if (sys.is_nil(ret)) {
            timeout = true;
            break;
        } fi

        timeout = false;
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
            if (sys.is_nil(uri[1]))
                action = 'index';
            else
                action = uri[1];
            if (!o || sys.has(o, action) != 'method') {
                R['code'] = 404;
            } else {
                if (sys.has(o, 'acl') == 'method') {
                    if (!(sys.has(o.acl(), action)) || !(o.acl()[action])) {
                        R['code'] = 404;
                        err = true;
                    } fi
                } fi
                if (!err) {
                    o.__action__ = action;
                    R['body'] = o.__action__();
                } fi
            }

            net.tcp_send(fd, http.create(R));
            break;
        } fi
    }

    if (timeout) {
        continue;
    } fi

    net.tcp_close(fd);
}
