#if !M_LOG
#define M_LOG
#include "@/../conf/conf.m"

Sys = Import('sys');
F = Import('file');

Log_path = '/tmp/Meproc.log';
Log_level = 'debug';

@Log_level_set(level)
{
    Log_level = level;
}

@Log_path_set(path)
{
    Log_path = path;
}

@Log(level, s)
{
    map = [
        'debug': 0,
        'info': 1,
        'warn': 2,
        'error': 3,
    ];

    if (map[level] < map[Log_level])
        return;
    fi

    tm = Sys.utctime(Sys.time());

    if (level == 'debug') {
        l = tm + " [DEBUG]: ";
        lc = "\e[36m" + tm + " [DEBUG]\e[0m: ";
    } else if (level == 'info') {
        l = tm + " [INFO]: ";
        lc = "\e[32m" + tm + " [INFO]\e[0m: ";
    } else if (level == 'warn') {
        l = tm + " [WARN]: ";
        lc = "\e[33m" + tm + " [WARN]\e[0m: ";
    } else {
        l = tm + " [ERROR]: ";
        lc = "\e[31m" + tm + " [ERROR]\e[0m: ";
    }

    f = $F;
    if (f.open(Log_path, 'a+')) {
        f.write(l + s + "\n");
        f.close();
    } else {
        Sys.print("Open log file [" + Log_path + "] failed, " + f.errmsg());
    }
    Sys.print(lc + s);
}

@TaskLog(alias, s)
{
    f = $F;
    if (f.open(Conf['log_dir'] + '/' + alias + '.log', 'a+')) {
        f.write(s);
        f.close();
    } else {
        Sys.print("Open log file [" + Conf['log_dir'] + '/' + alias + '.log' + "] failed, " + f.errmsg());
    }
}

Log_level_set(Conf['log_level']);
Log_path_set(Conf['log_dir'] + '/Meproc.log');

/*
 * Examples:
 *  Log_level_set('warn');
 *  Log('debug', "abc");
 *  Log('info', "abc");
 *  Log('warn', "abc");
 *  Log('error', "abc");
 *  TaskLog('aaa:1', 'test');
 */
#endif
