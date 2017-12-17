local router = require "dynx.resty.router"
local r = router:new("dynx.resty.router.redis_kv_cache")
local route, err = r:get_route(ngx.var.uri)
if not route and err then
  return ngx.exit(503)
end
if not route or route == ngx.null then
    return ngx.exit(404)
end
ngx.var.rr_key = ngx.var.uri
ngx.var.rr_route = route
ngx.var.rr_status = ngx.ctx.shcache["resty_router_cache"].cache_status
