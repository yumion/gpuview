#!/usr/bin/env python

"""
Web API of gpuview.

@author Fitsum Gaim
@url https://github.com/fgaim
"""

import json
import os
from datetime import datetime, timedelta

from bottle import TEMPLATE_PATH, Bottle, redirect, request, response, static_file, template

from . import core, utils

app = Bottle()
abs_path = os.path.dirname(os.path.realpath(__file__))
abs_views_path = os.path.join(abs_path, "views")
TEMPLATE_PATH.insert(0, abs_views_path)

EXCLUDE_SELF = False  # Do not report to `/gpustat` calls.


@app.route("/")
def index():
    hosts, gpustats = core.all_gpustats()
    booklist = core.get_reservation_status()
    now = datetime.now()
    is_time_over_gpus = core.check_deadline(now)
    for gpuid in is_time_over_gpus:
        core.cancel_gpu(gpuid)
    timestamp = now.strftime("Updated at %Y/%m/%d %H:%M:%S")
    return template("index", hosts=hosts, gpustats=gpustats, booklist=booklist, update_time=timestamp)


@app.route("/content", methods=["GET"])
def _index():
    hosts = core.load_hosts()
    for host in hosts:
        if host["name"] not in request.GET:
            host["display"] = False
        else:
            host["display"] = True
    hosts, gpustats = core.all_gpustats(hosts)
    booklist = core.get_reservation_status()
    now = datetime.now()
    is_time_over_gpus = core.check_deadline(now)
    for gpuid in is_time_over_gpus:
        core.cancel_gpu(gpuid)
    timestamp = now.strftime("Updated at %Y/%m/%d %H:%M:%S")
    return template("content", hosts=hosts, gpustats=gpustats, booklist=booklist, update_time=timestamp)


@app.route("/gpustat", methods=["GET"])
def report_gpustat():
    """
    Returns the gpustat of this host.
        See `exclude-self` option of `gpuview run`.
    """

    def _date_handler(obj):
        if hasattr(obj, "isoformat"):
            return obj.isoformat()
        else:
            raise TypeError(type(obj))

    response.content_type = "application/json"
    if EXCLUDE_SELF:
        resp = {"error": "Excluded self!"}
    else:
        resp = core.my_gpustat()
    return json.dumps(resp, default=_date_handler)


@app.route("/reserve", method=["POST"])
def reserve_gpu():
    username = request.forms.get("username")
    usagetime = request.forms.get("usagetime")  # [hour]
    finish_time = datetime.now() + timedelta(hours=int(usagetime))
    finish_time = finish_time.strftime("%m/%d %H:%M")
    gpu_id = request.forms.get("gpuId")
    core.add_gpu(gpu_id, username, finish_time)
    redirect("/")


@app.route("/cancel", method=["POST"])
def cancel_gpu():
    gpu_id = request.forms.get("gpuId")
    core.cancel_gpu(gpu_id)
    redirect("/")


@app.route("/host_display", methods=["GET"])
def host_display():
    hosts = core.load_hosts()
    for host in hosts:
        if host["name"] not in request.GET:
            host["display"] = False
        else:
            host["display"] = True
    hosts, _ = core.all_gpustats(hosts)
    core.save_hosts(hosts)
    redirect("/")


@app.route("/static/img/<filepath:re:.*\.(jpg|png|gif|ico|svg)>")
def img(filepath):
    print(filepath)
    return static_file(
        filepath,
        root=os.path.join(os.path.dirname(os.path.abspath(__file__)), "static", "img"),
    )


@app.get("/static/css/<filepath:re:.*\.css>")
def css(filepath):
    return static_file(
        filepath,
        root=os.path.join(os.path.dirname(os.path.abspath(__file__)), "static", "css"),
    )


def main():
    parser = utils.arg_parser()
    args = parser.parse_args()

    if "run" == args.action:
        core.safe_zone(args.safe_zone)
        global EXCLUDE_SELF
        EXCLUDE_SELF = args.exclude_self
        app.run(host=args.host, port=args.port, debug=args.debug)
    elif "service" == args.action:
        core.install_service(
            host=args.host,
            port=args.port,
            safe_zone=args.safe_zone,
            exclude_self=args.exclude_self,
        )
    elif "add" == args.action:
        core.add_host(args.url, args.name)
    elif "remove" == args.action:
        core.remove_host(args.name)
    elif "hosts" == args.action:
        core.print_hosts()
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
