FROM unidata/tomcat-docker:8
MAINTAINER Kyle Wilcox <kyle@axiomdatascience.com>

ENV ERDDAP_VERSION 1.74
ENV ERDDAP_CONTENT_URL http://coastwatch.pfeg.noaa.gov/erddap/download/erddapContent.zip
#ENV ERDDAP_CONTENT_URL http://coastwatch.pfeg.noaa.gov/erddap/download/erddapContent$ERDDAP_VERSION.zip
ENV ERDDAP_WAR_URL https://github.com/BobSimons/erddap/releases/download/v$ERDDAP_VERSION/erddap.war
ENV ERDDAP_DATA /erddapData

RUN \
    apt-get update && \
    apt-get install -y unzip && \
    curl -fSL "http://coastwatch.pfeg.noaa.gov/erddap/download/BitstreamVeraSans.zip" -o /BitstreamVeraSans.zip && \
    unzip /BitstreamVeraSans.zip -d ${JRE_HOME}/lib/fonts/ && \
    curl -fSL "${ERDDAP_CONTENT_URL}" -o /erddapContent.zip && \
    unzip /erddapContent.zip -d ${CATALINA_HOME} && \
    curl -fSL "${ERDDAP_WAR_URL}" -o /erddap.war && \
    unzip /erddap.war -d ${CATALINA_HOME}/webapps/erddap/ && \
    sed -i 's#</Context>#<Resources cachingAllowed="true" cacheMaxSize="100000" />\n&#' ${CATALINA_HOME}/conf/context.xml

# OOI Hackery!
RUN curl -fSL ftp://ftp.unidata.ucar.edu/pub/netcdf-java/v4.6/netcdfAll-4.6.8.jar -o ${CATALINA_HOME}/webapps/erddap/WEB-INF/lib/netcdfAll-latest.jar

# Java options
COPY files/setenv.sh ${CATALINA_HOME}/bin/setenv.sh

# ERDDAP setup.xml
COPY files/setup.xml ${CATALINA_HOME}/content/erddap/setup.xml

RUN mkdir -p ${ERDDAP_DATA} && \
    chown -R tomcat:tomcat "${ERDDAP_DATA}" && \
    chown -R tomcat:tomcat "${CATALINA_HOME}"

COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 8080 8443
CMD ["catalina.sh", "run"]
