# Qnap Package Build Tools

## reference
* [QDK 快速开发指南中文版](https://blog.233so.com/2020/05/qdk-quick-start-guide-zh/)
* [QPKG Development Guidelines - QNAPedia](https://wiki.qnap.com/wiki/QPKG_Development_Guidelines)
* [qnap-dev/QDK: QNAP Development Kit](https://github.com/qnap-dev/QDK)
* [qnap-dev/qdk2: QPKG development tool](https://github.com/qnap-dev/qdk2)
* [qnap-dev/QDK-Guide](https://github.com/qnap-dev/QDK-Guide)

## quick start
```bash
$ qbuild --create-env Hello # 在当前目录创建Hello工程文件夹
$ cd Hello
$ tree # 工程目录结构
├── arm-x09
├── arm-x19
├── arm-x31
├── arm-x41
├── arm_64
├── x86
├── x86_64
├── x86_ce53xx
├── build_sign.csv
├── config
├── icons
├── package_routines
├── qpkg.cfg
└── shared
    └── Hello.sh
$ rm -rf x86_ce53xx x86 arm-x09 arm-x19 arm-x31 arm-x41 # 去掉不需要的平台
$ tree
├── arm_64
│   └── hello # arm64平台可执行文件
├── x86_64
│   └── hello # x64平台可执行文件
├── build_sign.csv
├── config
├── icons
│   ├── Hello.gif # 小图标, 64x64
│   ├── Hello_80.gif # 大图标 80x80
│   └── Hello_gray.gif # 灰度图标, 64x64
├── package_routines
├── qpkg.cfg # 配置文件
└── shared
    └── Hello.sh # 启动脚本
$ qbuild # 在build文件夹下生成QPKG文件
```

## example
### qpkg.cfg
```bash
# Name of the packaged application.
QPKG_NAME="Hello"
# Name of the display application.
QPKG_DISPLAY_NAME="Hello World"
# Version of the packaged application. 
QPKG_VER="1.0.0"
# Author or maintainer of the package
QPKG_AUTHOR="Hello"
# License for the packaged application
QPKG_LICENSE="GNU General Public License v3.0"
# One-line description of the packaged application
QPKG_SUMMARY="A Hello World Example!"

# Preferred number in start/stop sequence.
QPKG_RC_NUM="101"
# Init-script used to control the start and stop of the installed application.
QPKG_SERVICE_PROGRAM="Hello.sh"
QPKG_SERVICE_PIDFILE="/var/run/hello.pid"
# Relative path to web interface
QPKG_WEBUI="/"
# Port number for the web interface.
QPKG_WEB_PORT="9999" # 不加此选项应用程序图标不会在桌面和程序栏显示
```

### Hello.sh
```bash
#!/bin/sh
CONF=/etc/config/qpkg.conf
QPKG_NAME="Hello" # 应用程序名
EXE_NAME="hello" # 可执行文件名
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
        $EXE_NAME & # 后台运行对应平台的可执行文件
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
```

## qbuild usage
```
$ qbuild -h
usage: qbuild [--extract QPKG [DIR]] [--create-env NAME] [-s|--section SECTION]
        [--root ROOT_DIR] [--build-arch ARCH] [--build-version VERSION]
        [--build-number NUMBER] [--build-model MODEL] [--build-dir BUILD_DIR]
        [--force-config] [--setup SCRIPT] [--teardown SCRIPT]
        [--pre-build SCRIPT] [--post-build SCRIPT] [--exclude PATTERN]
        [--exclude-from FILE] [--gzip|--bzip2|--7zip] [--sign] [--gpg-name ID]
        [--verify QPKG] [--add-sign QPKG] [--import-key KEY] [--remove-key ID]
        [--list-keys] [--query OPTION QPKG] [-v|--verbose] [-q|--quiet] [--strict]
        [--add-code-signing QPKG] [--verify-code-signing QPKG]
        [--code-signing-cfg CODE_SIGNING_CFG]
        [--allow-no-volume]
        [-?|-h|--help] [--usage] [-V|--version]

-s
--section SECTION
        Add SECTION to the list of searched sections in the configuration file.
        A section is a named set of definitions. By default, the DEFAULT section
        will be searched and then any sections specified on the command line.
--root ROOT_DIR
        Use files and meta-data in ROOT_DIR when the QPKG is built (default is
        the current directory, '.').
--build-version VERSION
        Use given version when QPKG is built (also updates the QPKG_VER
        definition in qpkg.cfg).
--build-number NUMBER
        Use given build number when QPKG is built.
--build-model MODEL
        Include check for given model in the QPKG package.
--build-arch ARCH
        Build QPKG for specified ARCH (supported values: arm-x09, arm-x19, arm-x31, arm-x41, arm_64, x86, x86_ce53xx,
        and x86_64). Only one architecture per option, but you can repeat the
        option on the command line to add multiple architectures.
--build-dir BUILD_DIR
        Place built QPKG in BUILD_DIR. If a full path is not specified then it
        is relative to the ROOT_DIR (default is ROOT_DIR/build).
--setup SCRIPT
        Run specified script to setup build environment. Called once before
        build process is initiated.
--teardown SCRIPT
        Run specified script to cleanup after all builds are finished. Called
        once after all builds are completed.
--pre-build SCRIPT
        Run specified script before the build process is started. Called before
        each and every build. First argument contains the architecture (one of
        arm-x09, arm-x19, arm-x31, arm-x41, arm_64, x86, x86_ce53xx, and x86_64) and the second argument contains the
        location of the architecture specific code. For the generic build the
        arguments are empty.
--post-build SCRIPT
        Run specified script after the build process is finished. Called after
        each and every build. First argument contains the architecture (one of
        arm-x09, arm-x19, arm-x31, arm-x41, arm_64, x86, x86_ce53xx, and x86_64) and the second argument contains the
        location of the architecture specific code. For the generic build the
        arguments are empty.
--create-env NAME
        Create a template build environment in the current directory
        for a QPKG named NAME.
--extract QPKG [DIR]
        Extract archive of files and meta-data from QPKG to DIR (default is
        current directory).
--exclude PATTERN
        Do not include files matching PATTERN in data package. This option is
        passed on to rsync and follows the same rules as rsync's --exclude
        option. Only one exclude pattern per option, but you can repeat the
        option on the command line to add multiple patterns.
--exclude-from FILE
        Related to --exclude, but specifies a FILE that contains exclude
        patterns (one per line). This option is passed on to rsync and follows
        the same rules as rsync's --exclude-from option.
--strict
        Treat warnings as errors.
--force-config
        Ignore missing configuration files specified in QPKG_CONFIG.
--gzip
        Compress QPKG content using gzip (this is the default compression when
        no compression option is specified.)
--bzip2
        Compress QPKG content using bzip2.
--7zip
        Compress QPKG content using 7-zip.
--query OPTION QPKG
        Retrieve information from QPKG. Available options:
          dump          dump settings from qpkg.cfg
          info          summary of settings in qpkg.cfg
          config        list configuration files
          require       list required packages
          conflict      list conflicting packages
          funcs         output package specific functions
--sign
        Generate and insert digital signature to QPKG. By default the first key
        in the secret keyring is used.
--gpg-name ID
        Use specified user ID to sign QPKG.
--verify QPKG
        Verify digital signature assigned to QPKG.
--add-sign QPKG
        Generate and insert digital signature to QPKG, replacing any existing
        signature.
--import-key KEY
        Import ASCII armored key to public keyring.
--list-keys
        Show keys in public keyring.
--remove-key ID
        Remove key with specified ID from public keyring.
--add-code-signing QPKG
        Add code signing digital signature into QPKG. By default configuration file 'qpkg.cfg' is used
--verify-code-signing QPKG
        Verify code signing digital signature in the QPKG. By default configuration file 'qpkg.cfg' is used
--code-signing-cfg CODE_SIGNING_CFG
        The configuration file for --add-code-signing and --verify-code-signing
--allow-no-volume
        Allow qpkg install without volume. The default path is /mnt/HDA_ROOT/update_pkg when the volume can not be found.
-?
-h
--help
        Show this help message.
--usage
        Display brief usage information.
-q
--quiet
        Silent mode. Do not write anything to standard output. Normally only
        error messages will be displayed.
-v
--verbose
        Verbose mode. Multiple options increase the verbosity. The maximum is 3.
-V
--version
        Print a single line containing the version number of QDK.
```
