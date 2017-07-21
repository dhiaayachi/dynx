local router = require "resty.router"
local r = router:new("resty.router.redis_dns")

local method = ngx.req.get_method()
local ok = nil
local err = nil
if method == ngx.HTTP_GET then
  ok, err = r:set_route(ngx.var.arg_location,ngx.var.arg_upstream,ngx.var.arg_ttl)
end
if method == ngx.HTTP_DELETE then
  ok, err = r:unset_route(ngx.var.arg_location)
end

if not ok then
    ngx.status = 500
    ngx.say(err)
    return ngx.exit(500)
end
ngx.var.rr_status = ok
