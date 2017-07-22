local router = require "resty.router"
local r = router:new("resty.router.redis_dns")

local method = ngx.req.get_method()
local ok = nil
local err = nil
if method == "GET" then
  ok, err = r:set_route(ngx.var.arg_location,ngx.var.arg_upstream,ngx.var.arg_ttl)
end
if method == "DELETE" then
  if ngx.var.arg_flushall and ngx.var.arg_flushall == "true" then
    ok, err = r:flushall(ngx.var.arg_location)
  else
    ok, err = r:unset_route(ngx.var.arg_location)
  end
end

if not ok then
    ngx.status = 500
    ngx.say(err)
    return ngx.exit(500)
end
ngx.var.rr_status = ok
