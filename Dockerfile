FROM scratch
COPY proxysql_exporter /proxysql_exporter
ENTRYPOINT ["/proxysql_exporter"]
