FROM alpine:3.20

RUN apk add --no-cache curl

COPY poll.sh /usr/local/bin/poll.sh
RUN chmod +x /usr/local/bin/poll.sh

ENTRYPOINT ["/usr/local/bin/poll.sh"]
