FROM openresty/openresty:alpine-fat
RUN luarocks install cluacov
RUN luarocks install  luacov-coveralls
COPY openresty_nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY upstream_rewrite.lua /usr/local/openresty/site/lualib/
COPY upstream_config.lua /usr/local/openresty/site/lualib/
COPY lib/resty /usr/local/openresty/site/lualib/resty
RUN touch luacov.stats.out
RUN chmod 777 luacov.stats.out
