FROM jetty:9.4
MAINTAINER Jon Herrmann <herrmann at interactive-instruments.de>
LABEL maintainer="Jon Herrmann <herrmann@interactive-instruments.de>"

LABEL Name="etf-webapp" Description="Testing framework for spatial data and services" Vendor="interactive instruments GmbH" Version=“2”

EXPOSE 8080

#
# Image build time configuration
#

ENV ETF_DIR /etf
ENV ETF_LOG_DIR /etf/logs

ENV ETF_RELATIVE_URL etf-webapp

# Possible values: “latest”, <version as MAJOR.MINOR.BUGFIX> e.g. “2.0.0” or
# <version as MAJOR.MINOR> e.g. “1.0” to get the latest bugfix version
ENV ETF_WEBAPP_VERSION latest

# Possible values: “latest”, <version as MAJOR.MINOR.BUGFIX> or
# <version as MAJOR.MINOR>
# Packed with the Webapp
ENV ETF_TESTDRIVER_BSX_VERSION latest

# Possible values: “latest”, <version as MAJOR.MINOR.BUGFIX> or
# <version as MAJOR.MINOR>
# Will be downloaded
ENV ETF_GMLGEOX_VERSION latest

# Possible values: “latest”, <version as MAJOR.MINOR.BUGFIX> or
# <version as MAJOR.MINOR>
# Packed with the Webapp
ENV ETF_TESTDRIVER_SUI_VERSION latest

# Possible values: “latest”, <version as MAJOR.MINOR.BUGFIX> or
# <version as MAJOR.MINOR>
# Packed with the Webapp
ENV ETF_TESTDRIVER_TE_VERSION latest

# Default repository configuration (where software artifacts are downloaded from)
ENV REPO_URL https://services.interactive-instruments.de/etfdev-af/etf-public-dev
ENV REPO_USER etf-public-dev
ENV REPO_PWD etf-public-dev

#
# Runtime configuration
#

# Possible values: “none” or URL to ZIP file
ENV ETF_DL_TESTPROJECTS_ZIP https://github.com/inspire-eu-validation/ets-repository/archive/master.zip
# Subfolder in the projects directory
ENV ETF_DL_TESTPROJECTS_DIR_NAME inspire-ets-repository
# Possible values: true for overwriting the directory on every container start,
# false for keeping an existing directory
ENV ETF_DL_TESTPROJECTS_OVERWRITE_EXISTING true

# Maximum JAVA heap size (XmX parameter) in MB or “max” (max available memory-768MB if at least 3GB available)
ENV MAX_MEM max

# Activate HTTP proxy server by setting a host (IP or DNS name).
# Default: "none" for not using a proxy server
ENV HTTP_PROXY_HOST none
# HTTP proxy server port. Default 8080. If you are using Squid it is 3128
ENV HTTP_PROXY_PORT 8080
# Optional username for authenticating against HTTP proxy server or "none" to
# deactivate authentication
ENV HTTP_PROXY_USERNAME none
# Optional password for authenticating against HTTP proxy server or "none"
ENV HTTP_PROXY_PASSWORD none

# Activate HTTP Secure proxy server by setting a host (IP or DNS name).
# Default: "none" for not using a proxy server
ENV HTTPS_PROXY_HOST none
# HTTP Secure proxy server port. Default 3129.
ENV HTTPS_PROXY_PORT 3129
# Optional username for authenticating against HTTPS proxy server or "none" to
# deactivate authentication
ENV HTTPS_PROXY_USERNAME none
# Optional password for authenticating against HTTP Secure proxy server or "none"
ENV HTTPS_PROXY_PASSWORD none

#
# Add build info - see hooks/build and https://github.com/opencontainers/image-spec/blob/master/annotations.md
#
ARG BUILD_DATE
ARG VCS_REF
ARG VCS_URL
LABEL org.opencontainers.image.created=$BUILD_DATE \
  org.opencontainers.image.source=$VCS_URL \
  org.opencontainers.image.revision=$VCS_REF

#
# Initialize image (download ETF and plugins)
#

USER root
# Backup original entrypoint
RUN mv /docker-entrypoint.sh /docker-entrypoint-jetty.sh
# Copy scripts
COPY res/ /
# Run init script
RUN /docker-init.sh

USER jetty

# Configure entrypoint
# Also download testprojects if configured
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["java","-jar","/usr/local/jetty/start.jar"]
