#include "@/log.m"
#include "@/validator.m"

J = Import('json');
S = Import('sys');
Str = Import('str');

Programs = [];
Delta = 0;

Proc {
    @rules() {
        return [
            'body': [
                ['field': 'name', 'type': 'string', 'required': true],
                ['field': 'cmd', 'type': 'string', 'required': true],
                ['field': 'type', 'type': 'string', 'required': true, 'in': ['once', 'daemon', 'cron']],
	        ['field': 'cron', 'type': 'string', 'required': false,],
                ['field': 'replica', 'type': 'int', 'required': true, 'default': 0],
                ['field': 'interval', 'type': 'int', 'required': false, 'default': 3],
                ['field': 'deps', 'type': 'array', 'required': false, 'element_type': 'string', 'default': []],
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
        return J.encode(['code': 200, 'msg': 'OK', 'data': [
            'running': S.exec(),
            'tasks': Programs,
        ]]);
    }

    @start() {
        body = this.get_json_body();
        if (!body) {
            R['code'] = 400;
            return J.encode(['code': 400, 'msg': 'JSON body is required']);
        } fi
        body['deps'];
        body['interval'];
        if (!(Validate(this.rules()['body'], body))) {
            R['code'] = 400;
            return J.encode(['code': 400, 'msg': 'Invalid JSON field']);
        } fi
        if (S.has(body, 'cron') && !(S.cron(body['cron'], S.time()))) {
            R['code'] = 400;
            return J.encode(['code': 400, 'msg': 'Invalid cron format']);
        } fi
        if (S.has(Programs, body['name']) && !(S.is_nil(Programs[body['name']]))) {
            R['code'] = 403;
            return J.encode(['code': 403, 'msg': 'Program exists, please stop it at first']);
        } fi
        if (!(Start(body))) {
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
        Stop(name);
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
        Stop(name);
        S.is_bool(Programs[name]['cron']) && Programs[name]['cron'] = nil;
        if (!(Start(Programs[name]))) {
            R['code'] = 400;
            return J.encode(['code': 400, 'msg': 'Start failed']);
        } fi
        return J.encode(['code': 200, 'msg': 'OK']);
    }
}

@Start(prog) {
    /*
    [
      {
        "name": "lstest",
        "cmd": "ls /",
        "type": "once",
        "cron": "* * * * *",
        "replica": 3,
        "interval": 3,
        "deps": []
      }
    ]
    */
    now = S.time();
    prog['start_time'] = now;
    if (Is_dep_running(prog)) {
        !(prog['cron']) && prog['cron'] = true;
        return true;
    } fi
    n = prog['replica'];
    name = prog['name'];
    prog['running'] = n;
    prog['last_time'] = now;
    S.has(prog, 'cron') && prog['cron'] && S.is_bool(prog['cron']) && prog['cron'] = nil;
    Log('info', 'Task ' + prog['name'] + ' started');
    for (i = 0; i < n; ++i) {
        alias = name + ':' + i;
        Eval('task.m', J.encode([
            'conf': prog,
            'alias': alias,
        ]), false, alias);
    }
    return true;
}

@Stop(name) {
    prog = Programs[name];
    if (Is_dep_running(prog))
        return;
    fi
    n = prog['replica'];
    Log('info', 'Task ' + prog['name'] + ' stopped');
    for (i = 0; i < n; ++i) {
        Kill(name + ':' + i);
    }
}

@Fetch_deps(prog, &set, in_set) {
    ret = [];
    chg = true;

    n = S.size(prog['deps']);
    for (i = 0; i < n; ++i) {
        name = prog['deps'][i];
        if (in_set && (!(S.has(set, name)) || S.is_nil(set[name]))) {
            continue;
        } fi
        ret[name] = name;
    }

    while (chg) {
        chg = false;
        n = S.size(ret);
        for (i = 0; i < n; ++i) {
            name = ret[i];
            if (!(S.has(set, name)) || S.is_nil(set[name]))
                continue;
            fi
            deps = set[name]['deps'];
            m = S.size(deps);
            for (j = 0; j < m; ++j) {
                if (in_set && (!(S.has(set, deps[j])) || S.is_nil(set[deps[j]]))) {
                    continue;
                } fi

                if (!(S.has(ret, deps[j]))) {
                    ret[deps[j]] = deps[j];
                    chg = true;
                } fi
            }
        }
    }
    return ret;
}

@Get_running_tasks() {
    ret = [];
    list = S.exec();
    n = S.size(list);
    for (i = 0; i < n; ++i) {
        name = Str.slice(list[i]['alias'], ':')[0];
        if (!(S.has(Programs, name)) || !(Programs[name])) {
            Log('error', "Task [" + name + "] is running but not in Programs"); 
            continue;
        } fi
        ret[name] = Programs[name];
    }
    return ret;
}

@Is_dep_running(prog) {
    tasks = Get_running_tasks();
    deps = Fetch_deps(prog, Programs);

    n = S.size(deps);
    for (i = 0; i < n; ++i) {
        if (S.has(tasks, deps[i]))
            return true;
        fi
    }

    return false;
}

@Get_immediate_tasks() {
    tasks = [];
    ret = [];
    n = S.size(Programs);
    for (i = 0; i < n; ++i) {
        prog = Programs[i];
        if (S.has(prog, 'cron') && prog['cron'] && S.is_bool(prog['cron'])) {
            tasks[prog['name']] = prog;
        } fi
    }

    n = S.size(tasks);
    for (i = 0; i < n; ++i) {
        t = tasks[i];
        !(Fetch_deps(t, tasks, true)) && ret[t['name']] = t;
    }

    return ret;
}

@cron_job_process() {
    //process cron @@@@@@@@@@@@@@@@@@@@@@@@
    //prog['type'] can be all of three values@@@@@@@@@@@@
    //prog['cron'] can be regular format or true@@@@@@@@@@@@@
    tasks = Get_immediate_tasks();
    n = S.size(tasks);
    for (i = 0; i < n; ++i) {
        Start(tasks[i]);
    }
}

