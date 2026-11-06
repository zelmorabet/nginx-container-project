FROM maven:3.9.9-eclipse-temurin-17 AS build
WORKDIR /workspace
COPY app/pom.xml app/pom.xml
COPY app/src app/src
COPY config.json config.json
RUN cp config.json app/src/main/webapp/config.json && mvn -B -f app/pom.xml clean package

FROM tomcat:10.1-jdk17-temurin
LABEL org.opencontainers.image.title="Tomcat Java Demo" \
      org.opencontainers.image.description="Java Servlet WAR deployed on Apache Tomcat"
RUN rm -rf /usr/local/tomcat/webapps/*
COPY tomcat/server.xml /usr/local/tomcat/conf/server.xml
COPY --from=build /workspace/app/target/ROOT.war /usr/local/tomcat/webapps/ROOT.war
EXPOSE 8080
CMD ["catalina.sh", "run"]
