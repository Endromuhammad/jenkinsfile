FROM asia-southeast2-docker.pkg.dev/it-infrastructure-service/docker-repository/java:17-openjdk

# Environment Variables
COPY --from=docker.elastic.co/observability/apm-agent-java:1.35.0 /usr/agent/elastic-apm-agent.jar /app/elastic-apm-agent.jar
ENV APM_AGENT=elastic-apm-agent.jar
ENV APM_NAME=uat-be-domain-order
ENV APM_PACKAGE=com.adira
ENV ENV_NAME=maple-uat
ENV APM_URL=http://10.150.16.18:8200
ENV JAR_NAME=domainordermaple-0.0.1-SNAPSHOT.jar

# Timezone
ENV TZ="Asia/Jakarta"

# Working Directory
WORKDIR /app

# Files
COPY ./target/${JAR_NAME}  /app/${JAR_NAME}

# User Ownership and Permissions
RUN adduser adm-app -u 1000710000  \
    && chown -R adm-app /app
USER adm-app

ENTRYPOINT java ${JAVA_OPTS} \
    -javaagent:/app/elastic-apm-agent.jar \
    -Delastic.apm.service_name=${APM_NAME} \
    -Delastic.apm.environment_name=${ENV_NAME}\
    -Delastic.apm.disable_bootstrap_check=true \
	-Delastic.apm.central_config=false \
    -Delastic.apm.server_urls=${APM_URL} \
    -Delastic.apm.application_packages=${APM_PACKAGE} \
    -jar /app/${JAR_NAME}
