import time

from gpuview.core import load_hosts, req_host


def get_gpustats(ttl, retry, timeout):
    hosts = load_hosts()
    for host in hosts:
        req_host(host, ttl, retry, timeout)
    return


def main():
    while True:
        get_gpustats(20, 3, 3)
        time.sleep(8)


if __name__ == "__main__":
    main()
