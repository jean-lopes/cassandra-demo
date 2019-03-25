FROM openjdk:8-jre-alpine
ENTRYPOINT ["/usr/bin/java", "-jar", "/usr/share/demo/app.jar"]
ARG JAR_FILE
ADD target/${JAR_FILE} /usr/share/demo/app.jar
