# static-binary-socat

This repo contains a static build of socat-1.8.1.1
along with the Dockerfile and build script that can be used to build.  

The purpose here was to have an up-to-date static build of socat that would run under [blink](https://github.com/jart/blink) and [Haiku OS.](https://github.com/haiku)


## Building under Linux

```
cd socat
docker build -t static-binaries-socat .
docker run -v `pwd`/../binaries:/output static-binaries-socat

# After build is done
# cd /static-binaries/binaries/linux/x86_64
# zip socat.zip ./socat
# cp socat.zip Haiku OS
```
