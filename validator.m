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
        if (!sys.has(r, 'required') || !r['required']) {
            if (!sys.has(data, r['field']))
                continue;
            fi
        } else {
            if (!sys.has(data, r['field'])) {
                return false;
            } fi
        }

        field = r['field'];
        type = r['type'];
        if (sys.type(data[field]) != type) {
            if (!S.is_nil(data[field]) || !sys.has(r, 'default')) {
                return false;
            } fi
        } fi

        if (type == 'string') {
            if (sys.has(r, 'in')) {
                if (!in_array(r['in'], data[field])) {
                    return false;
                } fi
            } fi
            sys.has(r, 'default') && sys.is_nil(data[field]) && data[field] = r['default'];
        } else if (type == 'int') {
            sys.has(r, 'default') && sys.is_nil(data[field]) && data[field] = r['default'];
        } else if (type == 'array') {
            sys.has(r, 'default') && sys.is_nil(data[field]) && data[field] = r['default'];
            if (sys.has(r, 'element_type')) {
                elt_type = r['element_type'];
                elts = data[field];
                nelts = sys.size(elts);
                for (idx = 0; idx < nelts; ++idx) {
                    if (sys.type(elts[idx]) != elt_type) {
                        return false;
                    } fi
                }
            } fi
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
