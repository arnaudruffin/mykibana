FROM centos:7
EXPOSE 5601





# Add Reporting dependencies.
RUN yum update -y && yum install -y fontconfig freetype && yum clean all

WORKDIR /usr/share/kibana

# Set gid to 0 for kibana and make group permission similar to that of user
# This is needed, for example, for Openshift Open:
# https://docs.openshift.org/latest/creating_images/guidelines.html
# and allows Kibana to run with an uid
RUN curl -Ls https://artifacts.elastic.co/downloads/kibana/kibana-7.1.1-linux-x86_64.tar.gz | tar --strip-components=1 -zxf - && \
    ln -s /usr/share/kibana /opt/kibana && \
    chown -R 1000:0 . && \
    chmod -R g=u /usr/share/kibana && \
    find /usr/share/kibana -type d -exec chmod g+s {} \;

ENV ELASTIC_CONTAINER true
ENV PATH=/usr/share/kibana/bin:$PATH

# Set some Kibana configuration defaults.
COPY config/kibana.yml /usr/share/kibana/config/kibana.yml
RUN chown -R 1000:0 /usr/share/kibana/config/kibana.yml

# Add the launcher/wrapper script. It knows how to interpret environment
# variables and translate them to Kibana CLI options.
COPY bin/kibana-docker /usr/local/bin/
RUN chown -R 1000:0 /usr/local/bin/

# Ensure gid 0 write permissions for Openshift.
RUN find /usr/share/kibana -gid 0 -and -not -perm /g+w -exec chmod g+w {} \;

# Provide a non-root user to run the process.
RUN groupadd --gid 1000 kibana && \
    useradd --uid 1000 --gid 1000 \
      --home-dir /usr/share/kibana --no-create-home \
      kibana

USER 1000

LABEL org.label-schema.schema-version="1.0" \
  org.label-schema.vendor="Elastic" \
  org.label-schema.name="kibana" \
  org.label-schema.version="{{ elastic_version }}" \
  org.label-schema.url="https://www.elastic.co/products/kibana" \
  org.label-schema.vcs-url="https://github.com/elastic/kibana-docker" \
  license="Apache-2.0"


CMD ["/usr/local/bin/kibana-docker"]