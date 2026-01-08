FROM nginx:alpine

# Remove default config
RUN rm /etc/nginx/conf.d/default.conf

# Copy nginx configuration template
COPY app.conf.template /etc/nginx/templates/app.conf.template
COPY app-http.conf.template /etc/nginx/templates/app-http.conf.template

# Create directories for certbot
RUN mkdir -p /var/www/certbot

# Expose ports
EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
