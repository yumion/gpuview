import time, json, json
from gpuview.core import load_hosts, reset_flag, client
try:
    from urllib.request import urlopen
except ImportError:
    from urllib2 import urlopen

def get_gpustats(ttl, retry=3):
    """
    Aggregates the gpustats of all registered hosts and this host.

    Returns:
        list: pustats of hosts
    """
    hosts = load_hosts()
    for i in range(retry):
        hosts = req_hosts(hosts, ttl)
        if not len(hosts):
            break
    return

def req_hosts(hosts, ttl):
    timeout_hosts = []
    for host in hosts:
        if not req_host(host, ttl):
            timeout_hosts.append(host)
    return timeout_hosts

def req_host(host, ttl):
    try:
        raw_resp = urlopen(host['url'] + '/gpustat', timeout = 1)
        resp = raw_resp.read()
        if type(resp) != str:
            resp = resp.decode()
        gpustat = json.loads(resp)
        reset_flag(gpustat)
        raw_resp.close()
        if gpustat is not None and 'gpus' in gpustat:
            client.set(host['name'], json.dumps(gpustat), ttl)
        return True
    except Exception as e:
        print('Error: %s getting gpustat from %s' %
            (getattr(e, 'message', str(e)), host['url']))
        return False

def main():
    while True:
        get_gpustats(16)
        time.sleep(8)

if __name__ == '__main__':
    main()