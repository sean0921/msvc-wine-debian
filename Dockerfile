FROM debian:buster

RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y wget gnupg && \
    ( wget -O - -nc https://dl.winehq.org/wine-builds/winehq.key | apt-key add - ) && \
    ( wget -O - -nc https://download.opensuse.org/repositories/Emulators:/Wine:/Debian/Debian_10/Release.key | apt-key add - ) && \
    ( echo 'deb https://dl.winehq.org/wine-builds/debian/ buster main' >  /etc/apt/sources.list.d/wine.list ) && \
    ( echo 'deb https://download.opensuse.org/repositories/Emulators:/Wine:/Debian/Debian_10 ./' >> /etc/apt/sources.list.d/wine.list ) && \
    apt-get update && \
    apt-get install --install-recommends -y winehq-staging python msitools python-simplejson \
                                            python-six ca-certificates procps && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt/msvc

COPY lowercase fixinclude install.sh vsdownload.py ./
COPY wrappers/* ./wrappers/

RUN ./vsdownload.py --accept-license --dest /opt/msvc && \
    ./install.sh /opt/msvc && \
    rm lowercase fixinclude install.sh vsdownload.py && \
    rm -rf wrappers

# Initialize the wine environment. Wait until the wineserver process has
# exited before closing the session, to avoid corrupting the wine prefix.
RUN wine wineboot --init && \
    while pgrep wineserver > /dev/null; do sleep 1; done

# Later stages which actually uses MSVC can ideally start a persistent
# wine server like this:
#RUN wineserver -p && \
#    wine wineboot && \
