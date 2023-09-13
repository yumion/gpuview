#!/bin/bash
PORT=9988
poetry_path=/home/${USER}/.local/bin/poetry
$poetry_path run gpuview run --port $PORT --safe-zone ${@:1}
