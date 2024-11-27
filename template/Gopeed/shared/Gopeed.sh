#!/bin/sh
CONF=/etc/config/qpkg.conf
QPKG_NAME="Gopeed"
EXE_NAME="gopeed"
QPKG_ROOT=`/sbin/getcfg $QPKG_NAME Install_Path -f ${CONF}`
APACHE_ROOT=`/sbin/getcfg SHARE_DEF defWeb -d Qweb -f /etc/config/def_share.info`
export QNAP_QPKG=$QPKG_NAME
export QPKG_NAME QPKG_ROOT APACHE_ROOT

export SHELL=/bin/sh
export LC_ALL=en_US.UTF-8
export USER=admin
export LANG=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
export HOME=$QPKG_ROOT

export PIDF=/var/run/$EXE_NAME.pid

case "$1" in
    start)
        ENABLED=$(/sbin/getcfg $QPKG_NAME Enable -u -d FALSE -f $CONF)
        if [ "$ENABLED" != "TRUE" ]; then
            echo "$QPKG_NAME is disabled."
            exit 1
        fi

        /bin/ln -sf $QPKG_ROOT /opt/$QPKG_NAME
        /bin/ln -sf $QPKG_ROOT/$EXE_NAME /usr/bin/$EXE_NAME

        cd $QPKG_ROOT
        $EXE_NAME &
        echo $! > $PIDF
        ;;
    stop)
        if [ -e $PIDF ]; then
            ID=$(more $PIDF)
            kill -9 $ID
            rm -f $PIDF
        fi
        killall -9 $EXE_NAME
        rm -rf /opt/$QPKG_NAME
        rm -rf /usr/bin/$EXE_NAME
        ;;
    restart)
        $0 stop
        $0 start
        ;;
    *)
        echo "Usage: $0 {start|stop|restart}"
        exit 1
        ;;
esac

exit 0
