#include "@/../utils/log.m"

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

s.exec(cmd, -1, pid, conf['user'], conf['group'], alias);

msg = "Process " + pid + " (" + alias;
if (conf['user'] || conf['group']) {
    msg += " running as ";
    conf['user'] && (msg += conf['user']);
    msg += ':';
    conf['group'] && (msg += conf['group']);
} fi
msg += ") exit";
Log('info', msg);


m.send('http', EVAL_DATA);
