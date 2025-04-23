FROM nginx:1.25-alpine
COPY html/index.html /usr/share/nginx/html/
EXPOSE 80