FROM ubuntu

ARG DEBIAN_FRONTEND=noninteractive
RUN apt update
RUN apt install -y verilator python3 pip libpng-dev pkg-config git
RUN python3 -m pip install hdlmake
