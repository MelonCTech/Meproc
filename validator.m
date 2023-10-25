#if !M_VALIDATOR
#define M_VALIDATOR

S = Import('sys');

@Validate(rules, data)
{
    @in_array(arr, data) {
        n = S.size(arr);
        for (i = 0; i < n; ++i) {
            if (arr[i] == data)
                return true;
            fi
        }
        return false;
    }

    sys = S;
    n = sys.size(rules);

    for (i = 0; i < n; ++i) {
        r = rules[i];
        if (!(sys.has(r, 'required')) || !(r['required'])) {
            if (!(sys.has(data, r['field'])))
                continue;
            fi
        } else {
            if (!(sys.has(data, r['field'])))
                return false;
            fi
        }

        field = r['field'];
        type = r['type'];
        if (sys.type(data[field]) != type)
            return false;
        fi

        if (type == 'string') {
            if (sys.has(r, 'in')) {
                if (!(in_array(r['in'], data[field])))
                    return false;
                fi
            } fi
        } else if (type == 'int') {
            if (sys.has(r, 'default') && sys.is_nil(data[field]))
                data[field] = r['default'];
            fi
        } else {
            return false;
        }
    }
    return true;
}

/*
 * Example
 *  S.print(Validate([
 *      ['field': 'name', 'type': 'string', 'required': true],
 *      ['field': 'cmd', 'type': 'string', 'required': true],
 *      ['field': 'type', 'type': 'string', 'required': true, 'in': ['oneshot', 'regular']],
 *      ['field': 'cron', 'type': 'string', 'required': false],
 *      ['field': 'replica', 'type': 'int', 'required': false, 'default': 0],
 *  ], [
 *      'name': 'lstest',
 *      "cmd": "ls /",
 *      "type": "oneshot",
 *      "cron": "* * * * *",
 *      "replica": 3,
 *  ]));
 */
#endif
