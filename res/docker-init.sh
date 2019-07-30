#!/bin/bash

# Requires:
# -unzip
# -curl
# -wget

set -e

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

set -x

# $1 relative path, $2 egrep regex, $3 destination
getLatestFromII() {
    url=$basicArtifactoryUrl/$1
    eex=$2
    dest=$3
    versionSubPath=$(wget -O- $url | grep -v "maven" | grep -o -E 'href="([^"#]+)"' | cut -d'"' -f2 | sort -V | tail -1)
    latest=$(wget -O- $url/$versionSubPath | egrep -o $eex | sort -V | tail -1)
    echo $latest
    wget -q $url/$versionSubPath/$latest -O $dest
    # TODO verifiy checksum
    md5sum $dest
    chown -R $appServerUserGroup $dest
}

# $1 relative path, $2 egrep regex, $version, $4 destination
getSpecificFromII() {
    url=$basicArtifactoryUrl/$1
    eex=$2
    version=$3
    dest=$4
    versionSubPath=$(wget -O- $url | grep -v "maven" | grep $version | grep -o -E 'href="([^"#]+)"' | cut -d'"' -f2 | sort -V | tail -1)
    latest=$(wget -O- $url/$versionSubPath | egrep -o $eex | sort -V | tail -1)
    wget -q $url/$versionSubPath/$latest -O $dest
    # TODO verifiy checksum
    md5sum $dest
    chown -R $appServerUserGroup $dest
}

# $1 full path with artifact name and version, $2 destination
getFrom() {
    url=$1
    dest=$2
    wget -q $url -O $dest
}

#$1 relative path, $2 egrep, $3 configured value, $4 destination
get() {
    if [ "$3" == "latest" ]; then
        getLatestFromII $1 $2 $4
    else
        getSpecificFromII $1 $2 $3 $4
    fi
}

mkdir -p "$ETF_DIR"/bak
mkdir -p "$ETF_DIR"/td
mkdir -p "$ETF_DIR"/logs
mkdir -p "$ETF_DIR"/http_uploads
mkdir -p "$ETF_DIR"/testdata
mkdir -p "$ETF_DIR"/ds/obj
mkdir -p "$ETF_DIR"/ds/appendices
mkdir -p "$ETF_DIR"/ds/attachments
mkdir -p "$ETF_DIR"/ds/db/repo
mkdir -p "$ETF_DIR"/ds/db/data
mkdir -p "$ETF_DIR"/projects
mkdir -p "$ETF_DIR"/config

if [ ! -n "$ETF_RELATIVE_URL" ]; then
    ETF_RELATIVE_URL=etf-webapp
fi

# Download Webapp
if [ ! -f "$appServerDeplPath/$ETF_RELATIVE_URL".war ]; then
    echo "Downloading ETF. This may take a while..."
    getFrom ${REPO_URL}/de/interactive_instruments/etf/etf-webapp/etf-webapp-${ETF_WEBAPP_VERSION}.war "$appServerDeplPath/$ETF_RELATIVE_URL".war
fi

# Download BaseX test driver
if [[ -n "$ETF_TESTDRIVER_BSX_VERSION" && "$ETF_TESTDRIVER_BSX_VERSION" != "none" ]]; then
  if ls "$ETF_DIR"/td/etf-bsxtd*.jar 1> /dev/null 2>&1; then
    echo "Using existing BSX test driver, skipping download"
  else
    echo "Downloading BSX test driver"
    getFrom ${REPO_URL}/de/interactive_instruments/etf/testdriver/etf-bsxtd/etf-bsxtd-${ETF_TESTDRIVER_BSX_VERSION}.jar /tmp/etf-bsxtd.jar
    mv /tmp/etf-bsxtd.jar "$ETF_DIR"/td
  fi
fi

# Download GmlGeoX
if [[ ! -f "$ETF_DIR"/ds/db/repo/de/interactive_instruments/etf/bsxm/GmlGeoX.jar && -n "$ETF_GMLGEOX_VERSION" && "$ETF_GMLGEOX_VERSION" != "none" ]]; then
  getFrom ${REPO_URL}/de/interactive_instruments/etf/testdriver/etf-gmlgeox/etf-gmlgeox-${ETF_GMLGEOX_VERSION}.jar /tmp/GmlGeoX.jar
  mkdir -p "$ETF_DIR"/ds/db/repo/de/interactive_instruments/etf/bsxm/
  mv /tmp/GmlGeoX.jar "$ETF_DIR"/ds/db/repo/de/interactive_instruments/etf/bsxm/
fi

# Download SoapUI test driver
if [[ -n "$ETF_TESTDRIVER_SUI_VERSION" && "$ETF_TESTDRIVER_SUI_VERSION" != "none" ]]; then
  if ls "$ETF_DIR"/td/etf-suitd*.jar 1> /dev/null 2>&1; then
    echo "Using existing SUI test driver, skipping download"
  else
    echo "Downloading SUI test driver"
    getFrom ${REPO_URL}/de/interactive_instruments/etf/testdriver/etf-suitd/etf-suitd-${ETF_TESTDRIVER_SUI_VERSION}.jar /tmp/etf-suitd.jar
    mv /tmp/etf-suitd.jar "$ETF_DIR"/td
  fi
fi

# Download TEAM Engine test driver
if [[ -n "$ETF_TESTDRIVER_TE_VERSION" && "$ETF_TESTDRIVER_TE_VERSION" != "none" ]]; then
  if ls "$ETF_DIR"/td/etf-tetd*.jar 1> /dev/null 2>&1; then
    echo "Using existing TE test driver, skipping download"
  else
    echo "Downloading TE test driver"
    getFrom ${REPO_URL}/de/interactive_instruments/etf/testdriver/etf-tetd/etf-tetd-${ETF_TESTDRIVER_TE_VERSION}.jar /tmp/etf-tetd.jar
    mv /tmp/etf-tetd.jar "$ETF_DIR"/td
  fi
fi


chmod 770 -R "$ETF_DIR"/td

chmod 775 -R "$ETF_DIR"/ds/obj
chmod 770 -R "$ETF_DIR"/ds/db/repo
chmod 770 -R "$ETF_DIR"/ds/db/data
chmod 770 -R "$ETF_DIR"/ds/appendices
chmod 775 -R "$ETF_DIR"/ds/attachments

chmod 777 -R "$ETF_DIR"/projects
chmod 777 -R "$ETF_DIR"/config

chmod 775 -R "$ETF_DIR"/http_uploads
chmod 775 -R "$ETF_DIR"/bak
chmod 775 -R "$ETF_DIR"/testdata

touch "$ETF_DIR"/logs/etf.log
chmod 775 "$ETF_DIR"/logs/etf.log

chown -fR $appServerUserGroup $ETF_DIR
