"""
Core functions of gpuview.

@author Fitsum Gaim
@url https://github.com/fgaim
"""

import json
import os
import subprocess

try:
    from urllib.request import urlopen
except ImportError:
    from urllib2 import urlopen

from pymemcache.client import base

from .utils import str2bool

ABS_PATH = os.path.dirname(os.path.realpath(__file__))
HOSTS_DB = os.path.join(ABS_PATH, "gpuhosts.db")
SAFE_ZONE = False  # Safe to report all details.

client = base.Client(("127.0.0.1", 11211))


def safe_zone(safe=True):
    global SAFE_ZONE
    SAFE_ZONE = safe


def my_gpustat():
    """
    Returns a [safe] version of gpustat for this host.
        # See `--safe-zone` option of `gpuview start`.
        # Omit sensitive details, eg. uuid, username, and processes.
        # Set color flag based on gpu temperature:
            # bg-warning, bg-danger, bg-success, bg-primary

    Returns:
        dict: gpustat
    """

    try:
        from gpustat import GPUStatCollection

        stat = GPUStatCollection.new_query().jsonify()
        delete_list = []
        for gpu_id, gpu in enumerate(stat["gpus"]):
            if gpu["processes"] is None:
                gpu["processes"] = []
            if type(gpu["processes"]) is str:
                delete_list.append(gpu_id)
                continue
            gpu["memory"] = round(
                float(gpu["memory.used"]) / float(gpu["memory.total"]) * 100
            )
            if SAFE_ZONE:
                gpu["users"] = len(set([p["username"] for p in gpu["processes"]]))
                user_process = [
                    "%s(%s,%sM)" % (p["username"], p["command"], p["gpu_memory_usage"])
                    for p in gpu["processes"]
                ]
                gpu["user_processes"] = " ".join(user_process)
            else:
                gpu["users"] = len(set([p["username"] for p in gpu["processes"]]))
                processes = len(gpu["processes"])
                gpu["user_processes"] = "%s/%s" % (gpu["users"], processes)
                gpu.pop("processes", None)
                gpu.pop("uuid", None)
                gpu.pop("query_time", None)

            gpu["flag"] = "bg-primary"
            if gpu["memory"] > 75:
                gpu["flag"] = "bg-danger"
            elif gpu["memory"] > 50:
                gpu["flag"] = "bg-warning"
            elif gpu["memory"] > 10:
                gpu["flag"] = "bg-success"

        if delete_list:
            for gpu_id in delete_list:
                stat["gpus"].pop(gpu_id)
        stat["display"] = True
        return stat
    except Exception as e:
        return {"error": "%s!" % getattr(e, "message", str(e))}


def reset_flag(gpustat):
    for gpu_id, gpu in enumerate(gpustat["gpus"]):
        gpu["flag"] = "bg-primary"
        if gpu["memory"] > 75:
            gpu["flag"] = "bg-danger"
        elif gpu["memory"] > 50:
            gpu["flag"] = "bg-warning"
        elif gpu["memory"] > 10:
            gpu["flag"] = "bg-success"


def all_gpustats(hosts=None, ttl=20, retry=3, timeout=3):
    """
    Aggregates the gpustats of all registered hosts and this host.

    Returns:
        list: pustats of hosts
    """

    gpustats = []
    mystat = my_gpustat()
    if "gpus" in mystat:
        gpustats.append(mystat)
    hosts = load_hosts() if hosts is None else hosts
    for host in hosts:
        if host["display"]:
            gpustat = client.get(host["name"])
            if gpustat is None:
                gpustat = req_host(host, ttl, retry, timeout)
            else:
                gpustat = json.loads(gpustat.decode())
            if gpustat is not None:
                gpustat["hostname"] = host["name"]
                gpustat["display"] = host["display"]
                gpustats.append(gpustat)
    return hosts, gpustats


def req_host(host, ttl, retry, timeout):
    for i in range(retry):
        try:
            raw_resp = urlopen(host["url"] + "/gpustat", timeout=timeout)
            resp = raw_resp.read()
            if type(resp) != str:
                resp = resp.decode()
            gpustat = json.loads(resp)
            reset_flag(gpustat)
            raw_resp.close()
            if gpustat is not None and "gpus" in gpustat:
                client.set(host["name"], json.dumps(gpustat), ttl)
            return gpustat
        except Exception as e:
            print(
                "Error: %s getting gpustat from %s"
                % (getattr(e, "message", str(e)), host["url"])
            )
    return None


def load_hosts():
    """
    Loads the list of registered gpu nodes from file.

    Returns:
        dict list: [{'name':name, 'url':url, 'display': display}, ... ]
    """

    hosts = []
    if not os.path.exists(HOSTS_DB):
        print("There are no registered hosts! Use `gpuview add` first.")
        return hosts

    for line in open(HOSTS_DB, "r"):
        try:
            name, url, display = line.strip().split(",")
            hosts.append({"name": name, "url": url, "display": str2bool(display)})
        except Exception as e:
            print("Error: %s loading host: %s!" % (getattr(e, "message", str(e)), line))
    return hosts


def save_hosts(hosts):
    with open(HOSTS_DB, "w") as f:
        for host in hosts:
            f.write("%s,%s,%s\n" % (host["name"], host["url"], host["display"]))


def add_host(url, name=None, display=True):
    url = url.strip().strip("/").replace(",", "")
    if name is None:
        name = url
    name = name.replace(",", "")
    hosts = load_hosts()
    hosts.append({"name": name, "url": url, "display": display})
    save_hosts(hosts)
    print("Successfully added host!")


def remove_host(name):
    hosts = load_hosts()
    names = [host["name"] for host in hosts]
    if hosts.pop(names.index(name)):
        save_hosts(hosts)
        print("Removed host: %s!" % name)
    else:
        print("Couldn't find host: %s!" % name)


def print_hosts():
    hosts = load_hosts()
    if len(hosts):
        # hosts = sorted(hosts.items(), key=lambda g: g[1])
        print("#   Name\tURL\tDISPLAY")
        for idx, host in enumerate(hosts):
            print(
                "%02d. %s\t%s\t%s"
                % (idx + 1, host["name"], host["url"], host["display"])
            )


def install_service(host=None, port=None, safe_zone=False, exclude_self=False):
    arg = ""
    if host is not None:
        arg += "--host %s " % host
    if port is not None:
        arg += "--port %s " % port
    if safe_zone:
        arg += "--safe-zone "
    if exclude_self:
        arg += "--exclude-self "
    script = os.path.join(ABS_PATH, "service.sh")
    subprocess.call('{} "{}"'.format(script, arg.strip()), shell=True)
