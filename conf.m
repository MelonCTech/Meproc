#if !M_CONF
#define M_CONF

Conf = [
    'ip': '127.0.0.1',
    'port': '8606',
    'log_level': 'debug',
    'log_path': '/tmp/Meproc.log',
];

/*
 * Example:
 *  sys = Import('sys');
 *  sys.print(Conf);
 */
#endif
