#include "@/../utils/event.m"

j = Import('json');
s = Import('sys');
m = Import('mq');

data = j.decode(EVAL_DATA);
conf = data['conf'];
alias = data['alias'];
type = conf['type'];
cmd = conf['cmd'];
interval = conf['interval'];

if (type == 'daemon') {
    s.msleep(interval);
} fi

process_start_event = data;

if (type != 'coroutine') {
    s.exec(cmd, -1, data['pid'], conf['user'], conf['group'], alias);
} else {
    name = '__' + type + '__:' + alias;
    Eval(cmd, EVAL_DATA, false, name);

    while (true) {
        list = Eval();
        if (!s.has(list, name))
            break;
        fi
        s.msleep(1000);
    }
}

process_stop_event = data;

m.send('http', EVAL_DATA);
