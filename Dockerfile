FROM alpine
RUN apk add --no-cache curl libxml2-utils
COPY . /app
CMD sh /app/updateNamesiloRecord.sh
