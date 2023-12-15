<img src="https://raw.githubusercontent.com/MelonCTech/Meproc/master/docs/logo.png" />


<br>

**Meproc** is a process management service that can start, stop, and restart specified programs in a specified manner through an HTTP API.

Features:
- Support Restful API to start, stop, restart process groups, and view currently running process groups
- Support some simple dependencies between process groups
- Support cron jobs
- Support one-time tasks
- Support setting execution users and user groups for processes
- Support multiple platforms: Windows, Linux, MacOS, etc.
- Support for collecting output content from task processes.
- Support for plugin development based on process start and stop events.
- Provide a Web Page for Task Management.
- The project only needs to pre-install the Melang interpreter, and no more others need to be installed.


## Web UI Screenshot

<img src="https://raw.githubusercontent.com/MelonCTech/Meproc/master/docs/webui.png" />


## Installation

Meproc is written in [Melang](https://github.com/Water-Melon/Melang) language, which means that you need to install and only install Melang, then Meproc can be started up.

You can pull the built docker image.

```
docker pull melonc/meproc
```

You can refer to the [Wiki](https://github.com/MelonCTech/Meproc/wiki) for more installation approaches.



## Quick Start



### Start Meproc

```bash
melang meproc.m
```

Then you can see the output that Meproc service listening address.

The default IP is `127.0.0.1` and port is `8606`.



### Start process

Here is a simple example.

```bash
curl -v -XPOST http://127.1:8606/proc -d '{"name": "sleep1", "cmd": "sleep 5", "type": "once", "replica": 2, "user": "guest"}'
```

Using a POST HTTP request to start up a new process.

`name` is the task name. One task is a group of same processes. In this example, we will start up two process to run `sleep 5`.

`once` means that the processes in this task will only be executed once. And there are four values of `type` field:

- `once` means this task will only be executed once even if it exits unexpectedly.
- `daemon` means this task is a daemon, so if this process exits in any reason, it will be restarted.
- `cron` means this task is a cron job, it will contain a field named `cron` in task JSON.
- `coroutine` means that this task is a melang coroutine task. It will start a melang coroutine based on the provided script file path.


`user` indicates the user of the new process. Please make sure that Meproc has the permission to do this. `user` and `group` are NOT working on Windows.



Let's take a look at another example.

```bash
curl -v -XPOST http://127.1:8606/proc -d '{"name": "sleep2", "cmd": "sleep 5", "type": "once", "replica": 2, "deps": ["sleep1"]}'
```

`deps` indicates the list of task names that this task depends on.

The meaning of "dependency" is that when a task is going to be executed, if it finds that the tasks in the `deps` field are already running, it will wait for those tasks to finish before being executed. If the task in the `deps` field of this task has never been executed, it will not prevent this task from being executed.



A cron job example.

```bash
curl -v -XPOST http://127.1:8606/proc -d '{"name": "sleep2", "cmd": "sleep 5", "type": "cron", "cron": "* * * * *", "replica": 2}'
```

This task will be executed every minute.



### Stop process

Let's stop out `sleep1` task.

```bash
curl -v -XDELETE http://127.1:8606/proc?name=sleep1
```



### Restart process

Let's restart task `sleep2`.

```bash
curl -v -XPUT http://127.1:8606/proc?name=sleep2
```

 Restart will stop this task and start it again. And restart is only working on the tasks those are not stopped by `curl -v -XDELETE http://127.1:8606/proc?name=<proc_name>`.



### List all tasks and processes

```bash
curl -v -XGET http://127.1:8606/proc
```

An HTTP response with a JSON body will be returned.



### Change configuration

Configuration file is `conf/conf.m`.

```
Conf = [
    'ip': '0.0.0.0',
    'port': '8606',
    'log_level': 'debug',
    'log_dir': '/tmp',
    'web': [
        'ip': '127.0.0.1',
        'port': '8606',
    ],
    'bootstrap_cmd': '',
];
```

`Conf` is a variable that contains all configurations that Meproc needs. And the name `Conf` can not be changed and it is also case-sensitive.

The address in `web` is used to replace the address in Ajax requests on the web page, which is used to access Meproc to obtain process information. It should be set to the IP and port exposed by the host where Meproc is located."

You can find Meproc's log files and corresponding task process output log files under the directory specified by `log_dir`. Task process output log files are only supported on UNIX.


## Example

We start up Meproc, and run the commands that given below:

```bash
curl -v -XPOST http://127.1:8606/proc -d '{"name": "sleep1", "cmd": "sleep 5", "type": "once", "replica": 2}'

curl -v -XPOST http://127.1:8606/proc -d '{"name": "sleep2", "cmd": "sleep 5", "type": "once", "replica": 2, "deps": ["sleep1"]}'

curl -v -XPOST http://127.1:8606/proc -d '{"name": "sleep3", "cmd": "sleep 5", "type": "once", "replica": 2, "deps": ["sleep1", "sleep2"]}'

curl -v http://127.1:8606/proc

curl -v -XDELETE http://127.1:8606/proc?name=sleep1

curl -v -XPOST http://127.1:8606/proc -d '{"name": "sleep1", "cmd": "sleep 5", "type": "once", "replica": 2}'

curl -v -XPUT http://127.1:8606/proc?name=sleep1

curl -v -XPOST http://127.1:8606/proc -d '{"name": "sleep4", "cmd": "sleep 5", "type": "cron", "cron": "* * * * *", "replica": 2}'
```

We will see the output of Meproc like:

```
11/16/2023 15:22:38 UTC [INFO]: Meproc v1.0.6. Listen on: 0.0.0.0:8606
11/16/2023 15:22:43 UTC [INFO]: Task sleep1 started
11/16/2023 15:22:43 UTC [INFO]: Once Process (sleep1:0) start
11/16/2023 15:22:43 UTC [INFO]: Once Process (sleep1:1) start
11/16/2023 15:22:45 UTC [INFO]: Task sleep4 started
11/16/2023 15:22:45 UTC [INFO]: Cron Process (sleep4:0) start
11/16/2023 15:22:45 UTC [INFO]: Cron Process (sleep4:1) start
11/16/2023 15:22:48 UTC [INFO]: Once Process 47509 (sleep1:1) stop
11/16/2023 15:22:48 UTC [INFO]: Once Process 47507 (sleep1:0) stop
11/16/2023 15:22:48 UTC [INFO]: Task sleep2 started
11/16/2023 15:22:48 UTC [INFO]: Once Process (sleep2:0) start
11/16/2023 15:22:48 UTC [INFO]: Once Process (sleep2:1) start
11/16/2023 15:22:50 UTC [INFO]: Cron Process 47516 (sleep4:0) stop
11/16/2023 15:22:50 UTC [INFO]: Cron Process 47517 (sleep4:1) stop
11/16/2023 15:22:53 UTC [INFO]: Once Process 47518 (sleep2:0) stop
11/16/2023 15:22:53 UTC [INFO]: Once Process 47519 (sleep2:1) stop
11/16/2023 15:22:54 UTC [INFO]: Task sleep3 started
11/16/2023 15:22:54 UTC [INFO]: Once Process (sleep3:0) start
11/16/2023 15:22:54 UTC [INFO]: Once Process (sleep3:1) start
11/16/2023 15:22:59 UTC [INFO]: Once Process 47521 (sleep3:1) stop
11/16/2023 15:22:59 UTC [INFO]: Once Process 47520 (sleep3:0) stop
11/16/2023 15:24:00 UTC [INFO]: Task sleep4 started
11/16/2023 15:24:00 UTC [INFO]: Cron Process (sleep4:0) start
11/16/2023 15:24:00 UTC [INFO]: Cron Process (sleep4:1) start
11/16/2023 15:24:05 UTC [INFO]: Cron Process 47524 (sleep4:0) stop
11/16/2023 15:24:05 UTC [INFO]: Cron Process 47525 (sleep4:1) stop
11/16/2023 15:25:00 UTC [INFO]: Task sleep4 started
11/16/2023 15:25:00 UTC [INFO]: Cron Process (sleep4:0) start
11/16/2023 15:25:00 UTC [INFO]: Cron Process (sleep4:1) start
11/16/2023 15:25:05 UTC [INFO]: Cron Process 47527 (sleep4:1) stop
11/16/2023 15:25:05 UTC [INFO]: Cron Process 47526 (sleep4:0) stop
11/16/2023 15:26:00 UTC [INFO]: Task sleep4 started
11/16/2023 15:26:00 UTC [INFO]: Cron Process (sleep4:0) start
11/16/2023 15:26:00 UTC [INFO]: Cron Process (sleep4:1) start
11/16/2023 15:26:05 UTC [INFO]: Cron Process 47528 (sleep4:0) stop
11/16/2023 15:26:05 UTC [INFO]: Cron Process 47529 (sleep4:1) stop
...
```



## License

[BSD-3-Clause License](https://github.com/Water-Melon/Melang/blob/master/LICENSE)

Copyright (c) 2023-present, [MelonCTech](https://github.com/MelonCTech)


## Documentation

Please refer to our [Wiki](https://github.com/MelonCTech/Meproc/wiki) for more details.
