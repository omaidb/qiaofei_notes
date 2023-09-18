#!/usr/bin/env bash

# echo "start"
# java -javaagent:/opt/pinpoint/pinpoint-agent-2.1.0/pinpoint-bootstrap.jar -Dpinpoint.agentId=eureka1 -Dpinpoint.applicationName=woniuticket -jar /opt/qianyao/xm/eureka-server1-0.0.1-SNAPSHOT.jar >/var/log/qianyao/eureka1.log 2>&1 &
# java -javaagent:/opt/pinpoint/pinpoint-agent-2.1.0/pinpoint-bootstrap.jar -Dpinpoint.agentId=eureka2 -Dpinpoint.applicationName=woniuticket -jar /opt/qianyao/xm/eureka-server2-0.0.1-SNAPSHOT.jar >eureka2.log 2>&1 &
# java -javaagent:/opt/pinpoint/pinpoint-agent-2.1.0/pinpoint-bootstrap.jar -Dpinpoint.agentId=cinema -Dpinpoint.applicationName=woniuticket -jar /opt/qianyao/xm/cinema-stage-0.0.1-SNAPSHOT.jar >cinema.log 2>&1 &
# java -javaagent:/opt/pinpoint/pinpoint-agent-2.1.0/pinpoint-bootstrap.jar -Dpinpoint.agentId=jobs -Dpinpoint.applicationName=woniuticket -jar /opt/qianyao/xm/jobs-0.0.1-SNAPSHOT.jar >jobs.log 2>&1 &
# java -javaagent:/opt/pinpoint/pinpoint-agent-2.1.0/pinpoint-bootstrap.jar -Dpinpoint.agentId=comment -Dpinpoint.applicationName=woniuticket -jar /opt/qianyao/xm/comment-0.0.1-SNAPSHOT.jar >comment.log 2>&1 &
# java -javaagent:/opt/pinpoint/pinpoint-agent-2.1.0/pinpoint-bootstrap.jar -Dpinpoint.agentId=movie -Dpinpoint.applicationName=woniuticket -jar /opt/qianyao/xm/movie-stage-0.0.1-SNAPSHOT.jar >movie.log 2>&1 &
# java -javaagent:/opt/pinpoint/pinpoint-agent-2.1.0/pinpoint-bootstrap.jar -Dpinpoint.agentId=orders -Dpinpoint.applicationName=woniuticket -jar /opt/qianyao/xm/orders-stage-0.0.1-SNAPSHOT.jar >orders.log 2>&1 &
# java -javaagent:/opt/pinpoint/pinpoint-agent-2.1.0/pinpoint-bootstrap.jar -Dpinpoint.agentId=gateway -Dpinpoint.applicationName=woniuticket -jar /opt/qianyao/xm/gateway-0.0.1-SNAPSHOT.jar >gateway.log 2>&1 &
# java -javaagent:/opt/pinpoint/pinpoint-agent-2.1.0/pinpoint-bootstrap.jar -Dpinpoint.agentId=user -Dpinpoint.applicationName=woniuticket -jar /opt/qianyao/xm/user-0.0.1-SNAPSHOT.jar >user.log 2>&1 &
# java -javaagent:/opt/pinpoint/pinpoint-agent-2.1.0/pinpoint-bootstrap.jar -Dpinpoint.agentId=general -Dpinpoint.applicationName=woniuticket -jar /opt/qianyao/xm/general-0.0.1-SNAPSHOT.jar >general.log 2>&1 &
# java -javaagent:/opt/pinpoint/pinpoint-agent-2.1.0/pinpoint-bootstrap.jar -Dpinpoint.agentId=web -Dpinpoint.applicationName=woniuticket -jar /opt/qianyao/xm/web-0.0.1-SNAPSHOT.jar >web.log 2>&1 &
# echo "end"

AGENT_PATH=/opt/pinpoint/pinpoint-agent-2.1.0
AGENT_ID=123456
APPLICATION_NAME=woniu_test
VERSION=2.1.0

CATALINA_OPTS="$CATALINA_OPTS -javaagent:$AGENT_PATH/pinpoint-bootstrap-$VERSION.jar"
CATALINA_OPTS="$CATALINA_OPTS -Dpinpoint.agentId=$AGENT_ID"
CATALINA_OPTS="$CATALINA_OPTS -Dpinpoint.applicationName=$APPLICATION_NAME"
