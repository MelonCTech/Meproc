#include "@/log.m"

sys = Import('sys');

if (Conf['bootstrap_cmd']) {
    Log('info', 'running command [' + Conf['bootstrap_cmd'] + '] ...');
    sys.msleep(1000);
    sys.exec(Conf['bootstrap_cmd'], -1, pid, nil, nil, 'bootstrap');
} fi
