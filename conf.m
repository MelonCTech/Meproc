#if !M_CONF
#define M_CONF

F = Import('file');
J = Import('json');

Conf = [
    'ip': '127.0.0.1',
    'port': '1234',
    'worker': 4,
    'log_level': 'debug',
    'log_path': '/tmp/Meproc.log',
];

@Conf_load(path)
{
    if (!path)
        return true;
    fi

    f = $F;
    if (f.open(path, 'r') == false) {
        return false;
    } fi
    Conf = J.decode(f.read(f.size()));
    f.close();
    return true;
}

/*
 * Example:
 *  sys = Import('sys');
 *  sys.print(Conf_load('./conf.json'));
 *  sys.print(Conf);
 */
#endif
