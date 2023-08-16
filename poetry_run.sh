#!/bin/bash
PORT=9988
poetry run gpuview run --port $PORT --safe-zone ${@:1}
