FROM alpine
RUN apk add --update curl

WORKDIR /

COPY ./restartSibling.sh /

RUN chmod +x /restartSibling.sh

# wait 180 seconds (so nano-node is running)

CMD sleep 180 && ./restartSibling.sh