FROM openresty/openresty:alpine-fat
RUN luarocks install cluacov
RUN luarocks install  luacov-coveralls
COPY openresty_nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY upstream_rewrite.lua /usr/local/openresty/site/lualib/dynx/
COPY upstream_config.lua /usr/local/openresty/site/lualib/dynx/
COPY resty /usr/local/openresty/site/lualib/dynx/resty
COPY luacov.stats.out luacov.stats.out
COPY luacov.cfg /luacov.cfg
RUN chmod 777 luacov.stats.out
