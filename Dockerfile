FROM nginx:alpine@sha256:892bb2152464f0c5d8972593a5f5afaf8054552580b699d95f8ff4af08c2d33d

# Patch the one HIGH vulnerability present in the pinned base image
RUN apk add --no-cache libexpat=2.9.0-r0

# Generate a minimal nginx config for the unprivileged nginx user on port 8080
RUN { \
    echo 'pid /tmp/nginx.pid;'; \
    echo 'error_log /dev/stderr warn;'; \
    echo 'events { worker_connections 1024; }'; \
    echo 'http {'; \
    echo '    access_log off;'; \
    echo '    include /etc/nginx/mime.types;'; \
    echo '    default_type application/octet-stream;'; \
    echo '    server {'; \
    echo '        listen 8080;'; \
    echo '        root /usr/share/nginx/html;'; \
    echo '        index index.html;'; \
    echo '        location / {'; \
    echo '            try_files $uri $uri/ /index.html;'; \
    echo '        }'; \
    echo '        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|webp)$ {'; \
    echo '            expires 1y;'; \
    echo '            add_header Cache-Control "public, immutable";'; \
    echo '        }'; \
    echo '    }'; \
    echo '}'; \
} > /etc/nginx/nginx.conf && \
  chown -R nginx:nginx /usr/share/nginx/html /var/cache/nginx /tmp && \
  chmod -R g+rX /usr/share/nginx/html

# Copy static site content
COPY --chown=nginx:nginx dashboard.html /usr/share/nginx/html/index.html
COPY --chown=nginx:nginx docs/ /usr/share/nginx/html/docs/
COPY --chown=nginx:nginx repositories.json /usr/share/nginx/html/repositories.json
COPY --chown=nginx:nginx j1.yaml /usr/share/nginx/html/j1.yaml

EXPOSE 8080

USER nginx

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --spider -q http://localhost:8080/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
