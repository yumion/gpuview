"""
Web API of gpuview.

@author Fitsum Gaim
@url https://github.com/fgaim
"""

import os
from datetime import datetime, timedelta

from flask import (
    Flask,
    jsonify,
    redirect,
    render_template,
    request,
    send_from_directory,
)

from . import core, utils


abs_path = os.path.dirname(os.path.realpath(__file__))
abs_views_path = os.path.join(abs_path, "views")
app = Flask(__name__, template_folder=abs_views_path)


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
    return render_template(
        "index.html", hosts=hosts, gpustats=gpustats, booklist=booklist, update_time=timestamp, core=core
    )


@app.route("/content", methods=["GET"])
def _index():
    hosts = core.load_hosts()
    for host in hosts:
        host["display"] = host["name"] in request.args
    hosts, gpustats = core.all_gpustats(hosts)
    booklist = core.get_reservation_status()
    now = datetime.now()
    is_time_over_gpus = core.check_deadline(now)
    for gpuid in is_time_over_gpus:
        core.cancel_gpu(gpuid)
    timestamp = now.strftime("Updated at %Y/%m/%d %H:%M:%S")
    return render_template("content.html", hosts=hosts, gpustats=gpustats, booklist=booklist, update_time=timestamp)


@app.route("/gpustat", methods=["GET"])
def report_gpustat():
    """
    Returns the gpustat of this host.
        See `exclude-self` option of `gpuview run`.
    """
    resp = {"error": "Excluded self!"} if EXCLUDE_SELF else core.my_gpustat()
    return jsonify(resp)


@app.route("/reserve", methods=["POST"])
def reserve_gpu():
    username = request.form.get("username")
    usagetime = request.form.get("usagetime")  # [hour]
    finish_time = datetime.now() + timedelta(hours=int(usagetime))
    finish_time = finish_time.strftime("%m/%d %H:%M")
    gpu_id = request.form.get("gpuId")
    core.add_gpu(gpu_id, username, finish_time)
    return redirect("/")


@app.route("/cancel", methods=["POST"])
def cancel_gpu():
    gpu_id = request.form.get("gpuId")
    core.cancel_gpu(gpu_id)
    return redirect("/")


@app.route("/host_display", methods=["GET"])
def host_display():
    hosts = core.load_hosts()
    for host in hosts:
        host["display"] = host["name"] in request.args
    hosts, _ = core.all_gpustats(hosts)
    core.save_hosts(hosts)
    return redirect("/")


@app.route("/static/img/<path:filepath>")
def img(filepath):
    return send_from_directory(os.path.join(os.path.dirname(os.path.abspath(__file__)), "static", "img"), filepath)


@app.route("/static/css/<path:filepath>")
def css(filepath):
    return send_from_directory(os.path.join(os.path.dirname(os.path.abspath(__file__)), "static", "css"), filepath)


def main():
    parser = utils.arg_parser()
    args = parser.parse_args()

    if args.action == "run":
        core.safe_zone(args.safe_zone)
        global EXCLUDE_SELF
        EXCLUDE_SELF = args.exclude_self
        app.run(host=args.host, port=args.port, debug=args.debug)
    elif args.action == "service":
        core.install_service(
            host=args.host,
            port=args.port,
            safe_zone=args.safe_zone,
            exclude_self=args.exclude_self,
        )
    elif args.action == "add":
        core.add_host(args.url, args.name)
    elif args.action == "remove":
        core.remove_host(args.name)
    elif args.action == "hosts":
        core.print_hosts()
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
