FROM python:3.10
ARG PORT="9988"
ENV PORT=${PORT}

# https://northshorequantum.com/archives/dockerbuild_tz_hang.html
# Docker Build中に Configuring tzdataでハングするのを回避
ENV TZ Asia/Tokyo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update && apt-get install -y \
    software-properties-common \
    locales \
    vim \
    git \
    wget \
    python3-pip \
    libgl1-mesa-dev \
    memcached

# settings for japanese
RUN localedef -f UTF-8 -i ja_JP ja_JP.UTF-8
ENV LANG ja_JP.UTF-8
ENV LANGUAGE ja_JP:ja
ENV LC_ALL ja_JP.UTF-8

WORKDIR /app
COPY . .
RUN pip install --upgrade pip && pip install -r requirements.txt
RUN python setup.py develop

EXPOSE $PORT
RUN chmod +x entrypoint.sh
ENTRYPOINT ["/bin/bash", "-c", "./entrypoint.sh $PORT"]
