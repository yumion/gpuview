gpuview-enhanced
=======

[![LICENSE](https://img.shields.io/github/license/fgaim/gpuview.svg)](https://github.com/fgaim/gpuview/blob/master/LICENSE)
[![CircleCI](https://circleci.com/gh/fgaim/gpuview.svg?style=shield)](https://circleci.com/gh/fgaim/gpuview)
<!-- ![GitHub issues](https://img.shields.io/github/issues/fgaim/gpuview.svg)
[![PyPI](https://img.shields.io/pypi/v/gpuview.svg)](https://pypi.org/project/gpuview/) -->


GPU is an expensive resource, and deep learning practitioners have to monitor the
health and usage of their GPUs, such as the temperature, memory, utilization, and the users. 
This can be done with tools like `nvidia-smi` and `gpustat` from the terminal or command-line.
Often times, however, it is not convenient to `ssh` into servers to just check the GPU status. 
`gpuview` is meant to mitigate this by running a lightweight web dashboard on top of 
[`gpustat`][repo_gpustat].  

With `gpuview` one can monitor GPUs on the go, though a web browser. Moreover, **multiple GPU servers** can be registered into one `gpuview` dashboard and all stats are aggregated and accessible from one place.


Thumbnail view of GPUs across multiple servers.  

**!New Features in this fork:**
1. Select and save the multiple GPU servers for display
2. Memory cache for multiple GPU servers
3. Page auto refresh with a indicator of time to stale

![Screenshot of gpuview](https://github.com/XinNoil/gpuview/blob/main/imgs/dash-1.png)


Setup
-----

Python is required,`gpuview` has been tested with both 2.7 and 3 versions.

Install directly from repo:

```
$ pip install git+https://github.com/XinNoil/gpuview.git@main
$ pip install http://tjunet.top/gitbucket/XinNoil/gpuview-package/archive/master.zip
```

> `gpuview` installs the latest version of `gpustat` from `pypi`, therefore, its commands are available 
from the terminal.

Dependendencies
---------------

```
$ sudo apt-get install memcached
```

Usage
-----

`gpuview` can be used in two modes as a temporary process or as a background service.

### Run gpuview
Once `gpuview` is installed, it can be started as follows:
```
$ gpuview run --safe-zone
```
This will start the dasboard at `http://0.0.0.0:9988`.


By default, `gpuview` runs at `0.0.0.0` and port `9988`, but these can be changed using `--host` and `--port`. The `safe-zone` option means report all detials including usernames, but it can be turned off for security reasons.

### Run as a Service
To permanently run `gpuview` it needs to be deployed as a background service.
This will require a `sudo` privilege authentication.
The following command needs to be executed only once:

```
$ gpuview service [--safe-zone] [--exlude-self]
```

If successful, the `gpuview` service is run immediately and will also autostart at boot time. It can be controlled using `supervisorctl start|stop|restart gpuview`.


### Runtime options

There a few important options in `gpuview`, use `-h` to see them all.

```
$ gpuview -h
```

* `run`                : Start `gpuview` dashboard server
  * `--host`           : URL or IP address of host (default: 0.0.0.0)
  * `--port`           : Port number to listen to (default: 9988)
  * `--safe-zone`      : Safe to report all details, eg. usernames
  * `--exclude-self`   : Don't report to others but to self-dashboard
  * `-d`, `--debug`    : Run server in debug mode (for developers)
* `add`                : Add a GPU host to dashboard
  * `--url`            : URL of host [IP:Port], eg. http://<hostname:port>
  * `--name`           : Optional readable name for the host, eg. Node101
* `remove`             : Remove a registered host from dashboard
  * `--url`            : URL of host to remove, eg. http://<hostname:port>
* `hosts`              : Print out all registered hosts
* `service`            : Install `gpuview` as system service
  * `--host`           : URL or IP address of host (default: 0.0.0.0)
  * `--port`           : Port number to listen to (default: 9988)
  * `--safe-zone`      : Safe to report all details, eg. usernames
  * `--exclude-self`   : Don't report to others but to self-dashboard
* `-v`, `--version`    : Print versions of `gpuview` and `gpustat`
* `-h`, `--help`       : Print help for command-line options


### Monitoring multiple hosts

To aggregate the stats of multiple machines, they can be registered to one dashboard using their address and the port number running `gpustat`.

Register a host to monitor as follows:
```
$ gpuview add --url http://<hostname:port> --name <name>
```

Remove a registered host as follows:
```
$ gpuview remove --name <name>
```

Display all registered hosts as follows:
```
$ gpuview hosts
```

> Note: the `gpuview` service needs to run in all hosts that will be monitored.

> Tip: `gpuview` can be setup on a none GPU machine, such as laptops, to monitor remote GPU servers. 


etc
---

Helpful tips related to the underlying performance are available at the [`gpustat`][repo_gpustat] repo.


For the sake of simplicity, `gpuview` does not have a user authentication in place. As a security measure,
it does not report sensitive details such as user names by default. This can be changed if the service is 
running in a trusted network, using the `--safe-zone` option to report all details. 


The `--exclude-self` option of the run command can be used to prevent other dashboards from getting stats of the current machine. This way the stats are shown only on the host's own dashboard.


Detailed view of GPUs across multiple servers.  

![Screenshot of gpuview](https://github.com/XinNoil/gpuview/blob/main/imgs/dash-2.png)


```
python -m sshtunnel -U user -R 127.0.0.1:9988 -L 127.0.0.1:9988 -- ssh_address

pip install nvidia-ml-py==11.450.51
pip install gpustat==0.6.0
```

License
-------

[MIT License](LICENSE)



[repo_gpustat]: https://github.com/wookayin/gpustat
[pypi_gpuview]: https://pypi.python.org/pypi/gpuview
