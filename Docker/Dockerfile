FROM alpine:latest
RUN mkdir /hello
COPY name.txt /hello/name.txt
CMD cat /hello/name.txt
CMD echo "Hello,Rostelecom! Greeting from $(hostname -f)" && cat /hello/name.txt
