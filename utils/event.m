#if !M_EVENT
#define M_EVENT

#include "@/log.m"
#include "@/../events"

Sys = Import('sys');
Str = Import('str');

process_start_event = nil;
process_stop_event = nil;

@start_event_handler(&proc) {
    conf = proc['conf'];
    alias = proc['alias'];
    type = conf['type'];

    msg = Str.capitalize(type) + " Process (" + alias;
    if (conf['user'] || conf['group']) {
        msg += " running as ";
        conf['user'] && (msg += conf['user']);
        msg += ':';
        conf['group'] && (msg += conf['group']);
    } fi
    msg += ") start";
    Log('info', msg);

    name = Str.capitalize(proc['conf']['name']);
    o = $name;
    if (!o || !Sys.has(o, 'start'))
        return;
    fi
    o.start(proc);
    Sys.print(name);
}

@stop_event_handler(&proc) {
    conf = proc['conf'];
    alias = proc['alias'];
    pid = proc['pid'];
    type = conf['type'];

    msg = Str.capitalize(type) + " Process " + pid + " (" + alias;
    if (conf['user'] || conf['group']) {
        msg += " running as ";
        conf['user'] && (msg += conf['user']);
        msg += ':';
        conf['group'] && (msg += conf['group']);
    } fi
    msg += ") stop";
    Log('info', msg);

    name = Str.capitalize(conf['name']);
    o = $name;
    if (!o || !Sys.has(o, 'stop'))
        return;
    fi
    o.stop(proc);
    Sys.print(name);
}

Watch(process_start_event, start_event_handler);
Watch(process_stop_event, stop_event_handler);

#endif
/*
 * while (1) {
 *     process_start_event = ["conf": ['name':"example"]];
 *     process_stop_event = ["conf": ['name':"example"]];
 * }
 */

