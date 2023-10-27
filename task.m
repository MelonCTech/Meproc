#include "@/log.m"

j = Import('json');
s = Import('sys');
m = Import('mq');

data = j.decode(EVAL_DATA);
conf = data['conf'];
alias = data['alias'];
type = conf['type'];
cmd = conf['cmd'];
interval = conf['interval'];

again:

s.exec(cmd, 0, pid);
Log('info', "Process " + pid + " (" + alias + ") exit");

if (type == 'daemon') {
    s.msleep(interval);
    goto again;
} fi

m.send('http', conf['name']);
