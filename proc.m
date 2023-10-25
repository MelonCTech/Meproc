#include "@/validator.m"

/*
[
  {
    "name": "lstest",
    "cmd": "ls /",
    "type": "once",
    "cron": "* * * * *",
    "replica": 3
  },
  {
    "name": "echotest",
    "cmd": "echo 'aaa'",
    "type": "restart",
    "replica": 3
    "retry": 3,
    "interval": 3,
  }
]
*/
J = Import('json');
S = Import('sys');
Str = Import('str');

Proc {
    @rules() {
        return [
            ['field': 'name', 'type': 'string', 'required': true],
            ['field': 'cmd', 'type': 'string', 'required': true],
            ['field': 'type', 'type': 'string', 'required': true, 'in': ['oneshot', 'regular']],
            ['field': 'cron', 'type': 'string', 'required': false],
            ['field': 'replica', 'type': 'int', 'required': true, 'default': 0],
            ['field': 'retry', 'type': 'int', 'required': true, 'default': 3],
            ['field': 'interval', 'type': 'int', 'required': true, 'default': 3],
        ];
    }

    @acl() {
        return [
            'start': true,
            'restart': true,
            'list': true,
            'stop': true,
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

    @list() {
        R['headers']['Content-Type'] = 'application/json';
        if (R['method'] != 'GET') {
            R['code'] = 403;
            return J.encode(['code': 403, 'msg': 'Method not allowed']);
        } fi
        return J.encode(['code': 200, 'msg': 'OK', 'data': S.exec()]);
    }

    @start() {
        R['headers']['Content-Type'] = 'application/json';
        if (R['method'] != 'POST') {
            R['code'] = 403;
            return J.encode(['code': 403, 'msg': 'Method not allowed']);
        } fi
        body = this.get_json_body();
        if (!body) {
            return J.encode(['code': 400, 'msg': 'JSON body is required']);
        } fi
        //@@@@@@@@@@@@@@@@@@
        return J.encode(['code': 200, 'msg': 'OK']);
    }

    @stop() {
        R['headers']['Content-Type'] = 'application/json';
        if (R['method'] != 'GET') {
            R['code'] = 403;
            return J.encode(['code': 403, 'msg': 'Method not allowed']);
        } fi
        args = this.get_args();
        if (!args || !(S.has(args, 'id'))) {
            return J.encode(['code': 400, 'msg': 'id is required']);
        } fi
        //@@@@@@@@@@@@@@@@@@
        return J.encode(['code': 200, 'msg': 'OK']);
    }

    @restart() {
        R['headers']['Content-Type'] = 'application/json';
        if (R['method'] != 'GET') {
            R['code'] = 403;
            return J.encode(['code': 403, 'msg': 'Method not allowed']);
        } fi
        //@@@@@@@@@@@@@@@@@@ stop and start
    }
}
