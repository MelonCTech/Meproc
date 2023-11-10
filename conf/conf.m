#if !M_CONF
#define M_CONF

Conf = [
    'ip': '0.0.0.0',
    'port': '8606',
    'log_level': 'debug',
    'log_dir': '/tmp',
    'web': [
        'ip': '127.0.0.1',
        'port': '8606',
    ],
];

/*
 * Example:
 *  sys = Import('sys');
 *  sys.print(Conf);
 */
#endif
