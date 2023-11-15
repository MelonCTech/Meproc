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

s.exec(cmd, -1, data['pid'], conf['user'], conf['group'], alias);

process_stop_event = data;

m.send('http', EVAL_DATA);
