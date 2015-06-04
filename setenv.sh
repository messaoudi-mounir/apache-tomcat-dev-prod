# your customizations go here for any JAVA_OPTS and CATALINA_OPTS
# as well as any customized SERVER-WIDE configuration options
export CATLAINA_OPTS="$CATALINA_OPTS -Denv=SANDBOX"

# example of setting SOLR home for entire server
export JAVA_OPTS="$JAVA_OPTS -Dsolr.solr.home=/opt/index"


# JAVA home
export JRE_HOME="/usr/lib/jvm/java-7-openjdk-amd64"
export JAVA_HOME="/usr/usr/lib/jvm/java-7-openjdk-amd64"
