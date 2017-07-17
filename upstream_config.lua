local router = require "resty.router"
local r = router:new("resty.router.redis_dns")
local ok, err = r:set_route(ngx.var.arg_location,ngx.var.arg_upstream,ngx.var.arg_ttl)
if not ok then
    ngx.status = 404
    ngx.say(err)
    return ngx.exit(404)
end
ngx.var.rr_status = ok
