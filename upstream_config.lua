local router = require "dynx.resty.router"
local opts = {
  positive_ttl = 5,
  negative_ttl = 5,
  actualize_ttl = 5,
}
local r = router:new("dynx.resty.router.kv_cache",opts)

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
end
ngx.var.rr_status = ok
