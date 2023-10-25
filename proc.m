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
  }
]
*/
J = Import('json');
S = Import('sys');
Str = Import('str');

Proc {
    @proc() {
        if (R['method'] == 'GET') {
            return this.list();
        } else if (R['method'] == 'POST') {
            return this.update();
        } else if (R['method'] == 'PUT') {
            return this.create();
        } else if (R['method'] == 'DELETE') {
            return this.remove();
        } else {
            R['code'] = 400;
            return '';
        }
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
        return J.encode(['code': 200, 'msg': 'OK', 'data': S.exec()]);
    }

    @create() {
        R['headers']['Content-Type'] = 'application/json';
        body = this.get_json_body();
        if (!body) {
            return J.encode(['code': 400, 'msg': 'JSON body is required']);
        } fi
        //@@@@@@@@@@@@@@@@@@
        return J.encode(['code': 200, 'msg': 'OK']);
    }

    @remove() {
        R['headers']['Content-Type'] = 'application/json';
        args = this.get_args();
        if (!args || !(S.has(args, 'id'))) {
            return J.encode(['code': 400, 'msg': 'id is required']);
        } fi
        //@@@@@@@@@@@@@@@@@@
        return J.encode(['code': 200, 'msg': 'OK']);
    }

    @update() {
        //@@@@@@@@@@@@@@@@@@
    }
}
