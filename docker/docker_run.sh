PORT=9988
docker run --gpus all --rm -p $PORT:$PORT -it --name gpuview --hostname $(hostname) gpuview:python3.10
