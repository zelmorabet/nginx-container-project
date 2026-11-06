FROM nginx:1.28-alpine

LABEL org.opencontainers.image.title="Nginx Container Demo" \
      org.opencontainers.image.description="Configurable static website served by Nginx" \
      org.opencontainers.image.source="https://github.com/OWNER/REPOSITORY"

RUN rm -f /etc/nginx/conf.d/default.conf

COPY nginx/nginx.conf /etc/nginx/conf.d/default.conf
COPY app/ /usr/share/nginx/html/
COPY config.json /usr/share/nginx/html/config.json

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
