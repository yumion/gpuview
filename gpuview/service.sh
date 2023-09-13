#!/bin/sh

echo 'Install gpuview service:'

user=$USER
app_dir=/home/${user}/gpuview
option_cmd=${@:1}

echo ''
echo 'Installing supervisor...'
sudo apt install -y supervisor

echo ''
echo 'Deploying service...'

log_path=/home/${user}/.gpuview
mkdir -p ${log_path}

sudo echo "[program:gpuview]
user = ${user}
environment = HOME=\"/home/${user}\",USER=\"${user}\"
directory = ${app_dir}
command = bash poetry_run.sh ${option_cmd}
autostart = true
autorestart = true
stderr_logfile = ${log_path}/stderr.log
stdout_logfile = ${log_path}/stdout.log" \
| sudo tee /etc/supervisor/conf.d/gpuview.conf > /dev/null

sudo supervisorctl reread

echo ''
sudo service supervisor restart

echo ''
sudo supervisorctl restart gpuview

echo '~DONE~'
echo ''
echo 'Visit http://0.0.0.0:9988 in your browser.'
echo ''
