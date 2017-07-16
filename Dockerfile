FROM openresty/openresty:alpine-fat
COPY openresty_nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY upstream_rewrite.lua /usr/local/openresty/site/lualib/
COPY lib/resty /usr/local/openresty/site/lualib/resty
