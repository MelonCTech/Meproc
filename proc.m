#include "@/validator.m"

J = Import('json');
S = Import('sys');
Str = Import('str');

Programs = [];

Proc {
    @rules() {
        return [
            'body': [
                ['field': 'name', 'type': 'string', 'required': true],
                ['field': 'cmd', 'type': 'string', 'required': true],
                ['field': 'type', 'type': 'string', 'required': true, 'in': ['oneshot', 'regular']],
	        ['field': 'cron', 'type': 'string', 'required': false, 'default': '* * * * *'],
                ['field': 'replica', 'type': 'int', 'required': true, 'default': 0],
                ['field': 'retry', 'type': 'int', 'required': true, 'default': 3],
                ['field': 'interval', 'type': 'int', 'required': true, 'default': 3],
                ['field': 'deps', 'type': 'array', 'required': false, 'element_type': 'string'],
            ],
            'args': [
                ['field': 'name', 'type': 'string', 'required': true],
            ],
        ];
    }

    @acl() {
        return [
            'index': true,
        ];
    }

    @get_args() {
        args = R['args'];
        if (!args) {
            return [];
        } fi

        parts = Str.slice(args, '&');
        args = [];
        n = S.size(parts);
        for (i = 0; i < n; ++i) {
            arr = Str.slice(parts[i], '=');
            if (!arr || S.size(arr) != 2)
                continue;
            fi
            args[arr[0]] = arr[1];
        }
        return args;
    }

    @get_json_body() {
        if (!(R['body']))
            return nil;
        fi
        return J.decode(R['body']);
    }

    @index() {
        method = R['method'];
        R['headers']['Content-Type'] = 'application/json';

        if (method == 'GET') {
            return this.list();
        } else if (method == 'POST') {
            return this.restart();
        } else if (method == 'PUT') {
            return this.start();
        } else if (method == 'DELETE') {
            return this.stop();
        } fi
        R['code'] = 405;
        return J.encode(['code': 405, 'msg': 'Method not allowed']);
    }

    @list() {
        return J.encode(['code': 200, 'msg': 'OK', 'data': S.exec()]);
    }

    @start() {
        body = this.get_json_body();
        if (!body) {
            R['code'] = 400;
            return J.encode(['code': 400, 'msg': 'JSON body is required']);
        } fi
        if (!(Validate(this.rules()['body'], body))) {
            R['code'] = 400;
            return J.encode(['code': 400, 'msg': 'Invalid JSON field']);
        } fi
        if (S.has(Programs, body['name']) && !(S.is_nil(Programs[body['name']]))) {
            R['code'] = 403;
            return J.encode(['code': 403, 'msg': 'Program exists, please stop it at first']);
        } fi
        if (!(this.do_start(body))) {
            R['code'] = 400;
            return J.encode(['code': 400, 'msg': 'Start failed']);
        } fi
        Programs[body['name']] = body;
        return J.encode(['code': 200, 'msg': 'OK']);
    }

    @stop() {
        args = this.get_args();
        if (!(Validate(this.rules()['args'], args))) {
            R['code'] = 400;
            return J.encode(['code': 400, 'msg': 'name is required']);
        } fi
        name = args['name'];
        if (!(S.has(Programs, name)) || S.is_nil(Programs[name])) {
            R['code'] = 403;
            return J.encode(['code': 403, 'msg': 'Program not exists, please start it at first']);
        } fi
        this.do_stop(name);
        Programs[name] = nil;
        return J.encode(['code': 200, 'msg': 'OK']);
    }

    @restart() {
        args = this.get_args();
        if (!(Validate(this.rules()['args'], args))) {
            R['code'] = 400;
            return J.encode(['code': 400, 'msg': 'name is required']);
        } fi
        name = args['name'];
        if (!(S.has(Programs, name)) || S.is_nil(Programs[name])) {
            R['code'] = 403;
            return J.encode(['code': 403, 'msg': 'Program not exists, please start it at first']);
        } fi
        this.do_stop(name);
        if (!this.do_start(Programs[name])) {
            R['code'] = 400;
            return J.encode(['code': 400, 'msg': 'Start failed']);
        } fi
        return J.encode(['code': 200, 'msg': 'OK']);
    }

    @do_start(prog) {
        /*
        [
          {
            "name": "lstest",
            "cmd": "ls /",
            "type": "oneshot",
            "cron": "* * * * *",
            "replica": 3,
            "retry": 3,
            "interval": 3,
            "deps": []
          }
        ]
        */
        n = prog['replica'];
        name = prog['name'];
        data = J.encode(prog);
        for (i = 0; i < n; ++i) {
            Eval('task.m', data, false, name + ':' + i);
        }
        return true;
    }

    @do_stop(name) {
        prog = Programs[name];
        n = prog['replica'];
        for (i = 0; i < n; ++i) {
            Kill(name + ':' + i);
        }
    }
}
