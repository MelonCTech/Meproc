#include "@/../utils/log.m"
#include "@/../utils/validator.m"

J = Import('json');
S = Import('sys');
Str = Import('str');
Mq = Import('mq');

Tasks = [];
Delta = 0;

Proc {
    @rules() {
        return [
            'body': [
                ['field': 'name', 'type': 'string', 'required': true],
                ['field': 'cmd', 'type': 'string', 'required': true],
                ['field': 'type', 'type': 'string', 'required': true, 'in': ['once', 'daemon', 'cron']],
	        ['field': 'cron', 'type': 'string', 'required': false, 'default': '* * * * *'],
	        ['field': 'user', 'type': 'string', 'required': false,],
	        ['field': 'group', 'type': 'string', 'required': false,],
                ['field': 'replica', 'type': 'int', 'required': false, 'default': 1],
                ['field': 'interval', 'type': 'int', 'required': false, 'default': 3000],
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
        if (!R['body'])
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
            return this.start();
        } else if (method == 'PUT') {
            return this.restart();
        } else if (method == 'DELETE') {
            return this.stop();
        } fi
        R['code'] = 405;
        return J.encode(['code': 405, 'msg': 'Method not allowed']);
    }

    @list() {
        data = [];
        keys = S.keys(Tasks);
        n = S.size(keys);
        for (i = 0; i < n; ++i) {
            if (!Tasks[keys[i]])
                continue;
            fi
            data[keys[i]] = Tasks[keys[i]];
        }
        return J.encode(['code': 200, 'msg': 'OK', 'data': [
            'running': S.exec(),
            'tasks': data,
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
        body['replica'];
        body['last_time'] = 0;
        body['type'] == 'cron' && body['cron'];
        body['run_flag'] = false;
        if (!Validate(this.rules()['body'], body)) {
            R['code'] = 400;
            return J.encode(['code': 400, 'msg': 'Invalid JSON field']);
        } fi
        if (S.int(body['interval']) <= 0) {
            R['code'] = 400;
            return J.encode(['code': 400, 'msg': "Interval must be a positive integer'"]);
        } fi
        if (S.int(body['replica']) <= 0) {
            R['code'] = 400;
            return J.encode(['code': 400, 'msg': "Replica must be a positive integer'"]);
        } fi
        if (S.has(body, 'cron')) {
            if (body['type'] != 'cron') {
                R['code'] = 400;
                return J.encode(['code': 400, 'msg': "Type of cron job must be 'cron'"]);
            } fi
            if (!S.cron(body['cron'], S.time())) {
                R['code'] = 400;
                return J.encode(['code': 400, 'msg': 'Invalid cron format']);
            } fi
        } fi
        if (S.has(Tasks, body['name']) && !S.is_nil(Tasks[body['name']])) {
            R['code'] = 403;
            return J.encode(['code': 403, 'msg': 'Program exists, please stop it at first']);
        } fi
        if (!S.has(body, 'cron') && !Start(body)) {
            R['code'] = 400;
            return J.encode(['code': 400, 'msg': 'Start failed']);
        } fi
        Tasks[body['name']] = body;
        return J.encode(['code': 200, 'msg': 'OK']);
    }

    @stop() {
        args = this.get_args();
        if (!Validate(this.rules()['args'], args)) {
            R['code'] = 400;
            return J.encode(['code': 400, 'msg': 'name is required']);
        } fi
        name = args['name'];
        if (!S.has(Tasks, name) || S.is_nil(Tasks[name])) {
            R['code'] = 403;
            return J.encode(['code': 403, 'msg': 'Program not exists, please start it at first']);
        } fi
        Stop(name);
        Tasks[name] = nil;
        return J.encode(['code': 200, 'msg': 'OK']);
    }

    @restart() {
        args = this.get_args();
        if (!Validate(this.rules()['args'], args)) {
            R['code'] = 400;
            return J.encode(['code': 400, 'msg': 'name is required']);
        } fi
        name = args['name'];
        if (!S.has(Tasks, name) || S.is_nil(Tasks[name])) {
            R['code'] = 403;
            return J.encode(['code': 403, 'msg': 'Program not exists, please start it at first']);
        } fi
        Stop(name);
        if (!Start(Tasks[name])) {
            R['code'] = 400;
            return J.encode(['code': 400, 'msg': 'Start failed']);
        } fi
        return J.encode(['code': 200, 'msg': 'OK']);
    }
}

@Start(&prog) {
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
        prog['run_flag'] = true;
        return true;
    } fi
    n = prog['replica'];
    name = prog['name'];
    prog['running'] = n;
    prog['last_time'] = now;
    prog['run_flag'] = false;

    msg = 'Task ' + prog['name'];
    if (prog['user'] || prog['group']) {
        msg += " (as ";
        prog['user'] && (msg += prog['user']);
        msg += ':';
        prog['group'] && (msg += prog['group']);
        msg += ")";
    } fi
    msg += " started";
    Log('info', msg);

    for (i = 0; i < n; ++i) {
        alias = name + ':' + i;
        Eval('@/../coroutines/task.m', J.encode([
            'conf': prog,
            'alias': alias,
        ]), false, alias);
    }
    return true;
}

@Stop(name) {
    prog = Tasks[name];
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
        if (in_set && (!S.has(set, name) || S.is_nil(set[name]))) {
            continue;
        } fi
        ret[name] = name;
    }

    while (chg) {
        chg = false;
        n = S.size(ret);
        for (i = 0; i < n; ++i) {
            name = ret[i];
            if (!S.has(set, name) || S.is_nil(set[name]))
                continue;
            fi
            deps = set[name]['deps'];
            m = S.size(deps);
            for (j = 0; j < m; ++j) {
                if (in_set && (!S.has(set, deps[j]) || S.is_nil(set[deps[j]]))) {
                    continue;
                } fi

                if (!S.has(ret, deps[j])) {
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
        if (name == 'bootstrap')
            continue;
        fi
        if (!S.has(Tasks, name) || !Tasks[name]) {
            Log('error', "Task [" + name + "] is running but not in Tasks"); 
            continue;
        } fi
        ret[name] = Tasks[name];
    }
    return ret;
}

@Is_dep_running(prog) {
    tasks = Get_running_tasks();
    deps = Fetch_deps(prog, Tasks);

    n = S.size(deps);
    for (i = 0; i < n; ++i) {
        if (S.has(tasks, deps[i]))
            return true;
        fi
    }

    return false;
}

@Get_immediate_tasks() {
    tasks = [
        'run': [],
        'all': [],
    ];
    n = S.size(Tasks);
    for (i = 0; i < n; ++i) {
        prog = Tasks[i];
        if (prog && prog['run_flag']) {
            tasks['all'][prog['name']] = prog;
        } fi
    }

    n = S.size(tasks['all']);
    for (i = 0; i < n; ++i) {
        t = tasks['all'][i];
        !Fetch_deps(t, tasks['all'], true) && tasks['run'][t['name']] = t;
    }

    return tasks['run'];
}

@cron_job_process() {
    im_tasks = Get_immediate_tasks();
    n = S.size(im_tasks);
    for (i = 0; i < n; ++i) {
        Start(im_tasks[i]);
    }

    running_tasks = Get_running_tasks();
    now = S.time() / 60 * 60;
    n = S.size(Tasks);
    for (i = 0; i < n; ++i) {
        prog = Tasks[i];
        if (prog && S.has(prog, 'cron') && (!prog['run_flag']) && !S.has(running_tasks, prog['name']) && (now - prog['last_time']) >= 60) {
            next = S.cron(prog['cron'], now);
            if (next < now + Delta + 16)
                prog['run_flag'] = true;
            fi
        } fi
    }
    Delta = S.time() - now;
}

@process_output_receive() {
    n = S.size(Tasks);
    for (i = 0; i < n; ++i) {
        t = Tasks[i];
        if (!t)
            continue;
        fi
        m = t['replica'];
        name = t['name'];
        for (j = 0; j < m; ++j) {
            data = Mq.recv(name + ':' + j, 1);
            if (data) {
                TaskLog(name + ':' + j, data);
            } fi
        }
    }
    data = Mq.recv('bootstrap', 1);
    if (data) {
        TaskLog('bootstrap', data);
    } fi
}

