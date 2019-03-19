#!/bin/bash

# Requires:
# -unzip
# -curl
# -wget

basicArtifactoryUrl=$REPO_URL
appServerDeplPath=/var/lib/jetty/webapps
appServerUserGroup=jetty:jetty

wgetRcFile="/root/.wgetrc"
touch $wgetRcFile
echo "user=$REPO_USER" >> $wgetRcFile
echo "password=$REPO_PWD" >> $wgetRcFile

if [[ -n "$HTTP_PROXY_HOST" && "$HTTP_PROXY_HOST" != "none" ]] || [[ -n "$HTTPS_PROXY_HOST" && "$HTTPS_PROXY_HOST" != "none" ]]; then
  echo "use_proxy=on" >> $wgetRcFile
fi

javaHttpProxyOpts=""
if [[ -n "$HTTP_PROXY_HOST" && "$HTTP_PROXY_HOST" != "none" ]]; then
  if [[ -n "$HTTP_PROXY_USERNAME" && "$HTTP_PROXY_USERNAME" != "none" ]]; then
    echo "Using HTTP proxy server $HTTP_PROXY_HOST on port $HTTP_PROXY_PORT as user $HTTP_PROXY_USERNAME"
    javaHttpProxyOpts="-Dhttp.proxyHost=$HTTP_PROXY_HOST -Dhttp.proxyPort=$HTTP_PROXY_PORT -Dhttp.proxyUser=$HTTP_PROXY_USERNAME -Dhttp.proxyPassword=$HTTP_PROXY_PASSWORD"
    echo "http_proxy=http://$HTTP_PROXY_USERNAME:$HTTP_PROXY_PASSWORD@$HTTP_PROXY_HOST:$HTTP_PROXY_PORT" >> $wgetRcFile
  else
    echo "Using HTTP proxy server $HTTP_PROXY_HOST on port $HTTP_PROXY_PORT"
    javaHttpProxyOpts="-Dhttp.proxyHost=$HTTP_PROXY_HOST -Dhttp.proxyPort=$HTTP_PROXY_PORT"
    echo "http_proxy=http://$HTTP_PROXY_HOST:$HTTP_PROXY_PORT" >> $wgetRcFile
  fi
fi

javaHttpsProxyOpts=""
if [[ -n "$HTTPS_PROXY_HOST" && "$HTTPS_PROXY_HOST" != "none" ]]; then
  if [[ -n "$HTTPS_PROXY_USERNAME" && "$HTTPS_PROXY_USERNAME" != "none" ]]; then
    echo "Using HTTP Secure proxy server $HTTPS_PROXY_HOST on port $HTTPS_PROXY_PORT as user $HTTPS_PROXY_USERNAME"
    javaHttpsProxyOpts="-Dhttps.proxyHost=$HTTPS_PROXY_HOST -Dhttps.proxyPort=$HTTPS_PROXY_PORT -Dhttps.proxyUser=$HTTPS_PROXY_USERNAME -Dhttps.proxyPassword=$HTTPS_PROXY_PASSWORD"
    echo "https_proxy=https://$HTTPS_PROXY_USERNAME:$HTTPS_PROXY_PASSWORD@$HTTPS_PROXY_HOST:$HTTPS_PROXY_PORT" >> $wgetRcFile
  else
    echo "Using HTTP Secure proxy server $HTTPS_PROXY_HOST on port $HTTPS_PROXY_PORT"
    javaHttpsProxyOpts="-Dhttps.proxyHost=$HTTPS_PROXY_HOST -Dhttps.proxyPort=$HTTPS_PROXY_PORT"
    echo "https_proxy=https://$HTTPS_PROXY_HOST:$HTTPS_PROXY_PORT" >> $wgetRcFile
  fi
fi

set -x

max_mem_kb=0
xms_xmx=""
if [[ -n "$MAX_MEM" && "$MAX_MEM" != "max" && "$MAX_MEM" != "0" ]]; then
  re='^[0-9]+$'
  if ! [[ $MAX_MEM =~ $re ]] ; then
     echo "MAX_MEM: Not a number" >&2; exit 1
  fi
  max_mem_kb=$(($MAX_MEM*1024))
  xms_xmx="-Xms1g -Xmx${max_mem_kb}k"
else
  # in KB
  max_mem_kb=$(cat /proc/meminfo | grep MemTotal | awk '{ print $2 }')

  # 4 GB in kb
  if [[ $max_mem_kb -lt 4194304 ]]; then
    xms_xmx="-Xms1g"
  else
    # 2 GB for system
    xmx_kb=$(($max_mem_kb-2097152))
    xms_xmx="-Xms2g -Xmx${xmx_kb}k"
  fi
fi

if [[ $max_mem_kb -lt 1048576 ]]; then
  echo "At least 1GB ram is required"
  exit 1;
fi

JAVA_OPTIONS="-server -XX:+UseConcMarkSweepGC -XX:+UseParNewGC $xms_xmx $javaHttpProxyOpts $javaHttpsProxyOpts"
export JAVA_OPTIONS
echo "Using JAVA_OPTIONS: ${JAVA_OPTIONS}"

# Download Executable Test Suites
if [[ -n "$ETF_DL_TESTPROJECTS_ZIP" && "$ETF_DL_TESTPROJECTS_ZIP" != "none" ]]; then
  if [ "$ETF_DL_TESTPROJECTS_OVERWRITE_EXISTING" == "true" ]; then
    rm -R "$ETF_DIR"/projects/"$ETF_DL_TESTPROJECTS_DIR_NAME"
  fi
  if [ -d "$ETF_DIR"/projects/"$ETF_DL_TESTPROJECTS_DIR_NAME" ]; then
    echo "Using existing Executable Test Suites, skipping download"
  else
    wget -q "$ETF_DL_TESTPROJECTS_ZIP" -O projects.zip
    mkdir -p "$ETF_DIR"/projects/"$ETF_DL_TESTPROJECTS_DIR_NAME"
    unzip -o projects.zip -d "$ETF_DIR"/projects/"$ETF_DL_TESTPROJECTS_DIR_NAME"
    rm master.zip
  fi
fi


if ! command -v -- "$1" >/dev/null 2>&1 ; then
	set -- java -jar "$JETTY_HOME/start.jar" $javaHttpProxyOpts $javaHttpsProxyOpts "$@"
fi

if [ "$1" = "java" -a -n "$JAVA_OPTIONS" ] ; then
	shift
	set -- java -Djava.io.tmpdir=$TMPDIR $JAVA_OPTIONS $JAVA_OPTIONS "$@"
fi

exec "$@"
