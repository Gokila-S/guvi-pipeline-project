FROM nginx:alpine

# Static site: serve files directly via nginx
COPY index.html /usr/share/nginx/html/
COPY programs.html /usr/share/nginx/html/
COPY script.js /usr/share/nginx/html/
COPY styles.css /usr/share/nginx/html/
COPY guvi.png /usr/share/nginx/html/
COPY kec.png /usr/share/nginx/html/

EXPOSE 80
