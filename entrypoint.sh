#!/bin/bash
PORT=$1
gpuview run --port $PORT --safe-zone --exclude-self
