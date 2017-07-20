local router = require "resty.router"
local r = router:new("resty.router.redis_dns")

local method = ngx.req.get_method()
if method == ngx.HTTP_GET then
  local ok, err = r:set_route(ngx.var.arg_location,ngx.var.arg_upstream,ngx.var.arg_ttl)
end
if method == ngx.HTTP_DELETE then
  local ok, err = r:unset_route(ngx.var.arg_location)
end

if not ok then
    ngx.status = 404
    ngx.say(err)
    return ngx.exit(404)
end
ngx.var.rr_status = ok
