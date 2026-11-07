FROM ubuntu:22.04

RUN apt update && apt install -y gcc  

WORKDIR /test
COPY test.c /test/


RUN gcc test.c -o test > /dev/null 
CMD ["./test"]
