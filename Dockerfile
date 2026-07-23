FROM alpine:latest

# Install required tools
RUN apk add --no-cache \
    bash \
    python3 \
    hugo \
    nginx \
    dcron \
    tzdata

# Set timezone (adjust if needed)
ENV TZ=Europe/London

# Set up directory
WORKDIR /app

# Copy configuration files and scripts
COPY entrypoint.sh /entrypoint.sh
COPY generate_meteor_reports.sh /app/generate_meteor_reports.sh

# Make scripts executable
RUN chmod +x /entrypoint.sh /app/generate_meteor_reports.sh

# Set up Nginx configuration
RUN mkdir -p /run/nginx /usr/share/nginx/html
RUN echo 'server { \
    listen 80; \
    server_name _; \
    root /app/meteors/public; \
    index index.html; \
    location / { \
        try_files $uri $uri/ =404; \
    } \
}' > /etc/nginx/http.d/default.conf

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
