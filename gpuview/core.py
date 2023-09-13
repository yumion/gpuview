"""
Core functions of gpuview.

@author Fitsum Gaim
@url https://github.com/fgaim
"""

import json
import os
import subprocess
from datetime import datetime

try:
    from urllib.request import urlopen
except ImportError:
    from urllib2 import urlopen

from pymemcache.client import base

from .utils import str2bool

ABS_PATH = os.path.dirname(os.path.realpath(__file__))
HOSTS_DB = os.path.join(ABS_PATH, "gpuhosts.db")
RESERVATION_DB = os.path.join(ABS_PATH, "reservation_list.db")
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
            # MB to GB
            gpu["memory.used"] = f'{float(gpu["memory.used"]) / 1024:.0f}'  # [GB]
            gpu["memory.total"] = f'{float(gpu["memory.total"]) / 1024:.0f}'  # [GB]
            # memory rate
            gpu["memory"] = round(float(gpu["memory.used"]) / float(gpu["memory.total"]) * 100)
            gpu["users"] = len({p["username"] for p in gpu["processes"] if p["command"] != "Xorg"})
            if SAFE_ZONE:
                user_process = [
                    f'{p["username"]}({p["command"]},{p["pid"]})'
                    for p in gpu["processes"]
                    if p["command"] != "Xorg"  # ignore GUI process
                ]
                gpu["user_processes"] = " ".join(user_process)
            else:
                processes = len(gpu["processes"])
                gpu["user_processes"] = f'{gpu["users"]}/{processes}'
                gpu.pop("processes", None)
                gpu.pop("uuid", None)
                gpu.pop("query_time", None)

        if delete_list:
            for gpu_id in delete_list:
                stat["gpus"].pop(gpu_id)
        stat["display"] = True
        return stat
    except Exception as e:
        return {"error": f'{getattr(e, "message", str(e))}!'}


def all_gpustats(hosts=None, ttl=20, retry=1, timeout=1):
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
            # gpustat = None
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
    for _ in range(retry):
        try:
            raw_resp = urlopen(host["url"] + "/gpustat", timeout=timeout)
            resp = raw_resp.read()
            if type(resp) != str:
                resp = resp.decode()
            gpustat = json.loads(resp)
            raw_resp.close()
            if gpustat is not None and "gpus" in gpustat:
                client.set(host["name"], json.dumps(gpustat), ttl)
            return gpustat
        except Exception as e:
            print(f'Error: {getattr(e, "message", str(e))} getting gpustat from {host["name"]}')
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
            print(f'Error: {getattr(e, "message", str(e))} loading host: {line}!')
    return hosts


def save_hosts(hosts):
    with open(HOSTS_DB, "w") as fw:
        for host in hosts:
            fw.write("%s,%s,%s\n" % (host["name"], host["url"], host["display"]))


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
        print(f"Removed host: {name}!")
    else:
        print(f"Couldn't find host: {name}!")


def print_hosts():
    hosts = load_hosts()
    if len(hosts):
        # hosts = sorted(hosts.items(), key=lambda g: g[1])
        print("#   Name\tURL\tDISPLAY")
        for idx, host in enumerate(hosts):
            print("%02d. %s\t%s\t%s" % (idx + 1, host["name"], host["url"], host["display"]))


def install_service(host=None, port=None, safe_zone=False, exclude_self=False):
    arg = ""
    if host is not None:
        arg += f"--host {host} "
    if port is not None:
        arg += f"--port {port} "
    if safe_zone:
        arg += "--safe-zone "
    if exclude_self:
        arg += "--exclude-self "
    script = os.path.join(ABS_PATH, "service.sh")
    subprocess.call(f'{script} "{arg.strip()}"', shell=True)


def get_reservation_status():
    booklist = []
    if not os.path.exists(RESERVATION_DB):
        return booklist

    for line in open(RESERVATION_DB, "r"):
        try:
            gpuid, username, finishtime = line.strip().split(",")
            booklist.append({"gpuid": gpuid, "username": username, "finishtime": finishtime})
        except Exception as e:
            print(f'Error: {getattr(e, "message", str(e))} loading host: {line}!')
    return booklist


def save_gpu_booklist(booklist):
    with open(RESERVATION_DB, "w") as fw:
        for book in booklist:
            fw.write(f"{book['gpuid']},{book['username']},{book['finishtime']}\n")


def add_gpu(gpuid, username, finishtime):
    booklist = get_reservation_status()
    booklist.append({"gpuid": gpuid, "username": username, "finishtime": finishtime})
    save_gpu_booklist(booklist)


def cancel_gpu(gpuid):
    booklist = get_reservation_status()
    names = [book["gpuid"] for book in booklist]
    if booklist.pop(names.index(gpuid)):
        save_gpu_booklist(booklist)
        print(f"Cancel GPU: {gpuid}")
    else:
        print(f"The GPU {gpuid} is already cancelled")


def who_reserved_gpu(gpuid):
    booklist = get_reservation_status()
    return next((book["username"] for book in booklist if book["gpuid"] == gpuid), "")


def when_finish_reserve(gpuid):
    booklist = get_reservation_status()
    return next((book["finishtime"] for book in booklist if book["gpuid"] == gpuid), "")


def is_reserved(gpuid):
    booklist = get_reservation_status()
    return next(
        ("bg-danger" for book in booklist if book["gpuid"] == gpuid),
        "bg-primary",
    )


def check_deadline(now):
    booklist = get_reservation_status()
    is_time_over_gpus = []
    for book in booklist:
        finish_time = book["finishtime"]
        finish_time = datetime.strptime(finish_time, "%m/%d %H:%M").replace(year=now.year)
        if finish_time <= now:
            is_time_over_gpus.append(book["gpuid"])
    return is_time_over_gpus
