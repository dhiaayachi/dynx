local _M = {
    _VERSION = "0.1"
}
local mt = { __index = _M }
local setmetatable = setmetatable

local ok, cjson = pcall(require, "cjson")
if not ok then
    error("cjson module required")
end

local router = require "dynx.resty.router"
local log_info = router.log_info
local log_warn = router.log_warn
local log_err = router.log_err
local MINIMUM_TTL = router.MINIMUM_TTL
local DEFAULT_PREFIX = "resty_route:"
local client = nil
function _M.new(self, opts,index)
  local redis  = require "resty.redis"
  client = redis:new()
  client:set_timeout(1000)
  local ok, err = client:connect("redis-dyn", 6379)
  --if not ok then
  --    ngx.status = 503
  --    ngx.say("failed to connect: ", err)
  --    ngx.exit(ngx.HTTP_NOT_FOUND)
  -- end
  client:select(index)
  return setmetatable(self, mt)
end

function _M.set(self, key, upstream, ttl)
  local prefix = DEFAULT_PREFIX
  if router.prefix ~= nil then
    prefix = router.prefix
  end
  local prefix_key = prefix..key
  log_info("key:", prefix..key)
  local res, err  = client:hmset(prefix_key,"upstream",upstream,"ttl",ttl)
  log_info("res:", res,"err:",err,"p:",prefix_key,"u:",upstream,"t",ttl)
  if not res or res == ngx.null then
      return nil, cjson.encode({"Redis api not configured ofr", prefix_key, err})
  end
  return res, nil
end

function _M.unset(self, key)
  local prefix = DEFAULT_PREFIX
  if router.prefix ~= nil then
    prefix = router.prefix
  end
  local prefix_key = prefix..key
  log_info("key:", prefix..key)
  local ok, err = client:multi()
  if not ok then
    ngx.say("failed to run multi: ", err)
    return
  end
  local res, err  = client:hdel(prefix_key,"upstream")
  log_info("res:", res,"err:",err)
  if not res or res == ngx.null then
    return nil, cjson.encode({"Redis api not configured 1 for", prefix_key, err})
  end
  local res, err  = client:hdel(prefix_key,"ttl")
  log_info("res:", res,"err:",err)
  if not res or res == ngx.null then
    return nil, cjson.encode({"Redis api not configured 2 for", prefix_key, err})
  end
  res, err = client:exec()
  if not res or res == ngx.null then
    return nil, cjson.encode({"Redis api not configured 3 for", prefix_key, err})
  end
  return cjson.encode(res), nil
end

function _M.flushall(self)
  local ok, err = client:multi()
  if not ok  then
    return nil, cjson.encode({"Not able to clear the DB 1 ", err })
  end
  ok, err = client:select(1)
  if not ok or ok == ngx.null then
    return nil, cjson.encode({"Not able to clear the DB 2 ", err})
  end
  ok, err = client:flushdb()
  if not ok or ok == ngx.null then
    return nil, cjson.encode({"Not able to clear the DB 3 ", err})
  end
  ok, err = client:exec()
  if not ok or ok == ngx.null then
    return nil, cjson.encode({"Redis api not configured 4 ", err})
  end
  return cjson.encode(ok), nil
end

function _M.lookup(self, key)
  local prefix = DEFAULT_PREFIX
  if router.prefix ~= nil then
    prefix = router.prefix
  end
  local prefix_key = prefix..key
  log_info("key:", prefix..key)
  local answers, err  = client:hmget(prefix_key,"upstream","ttl")
  if not answers or #answers ~= 2 then
      return nil, cjson.encode({"Redis query failure", prefix_key, err})
  end
  if answers[1] == ngx.null then
      return nil, nil
  end

  local routes = {}
  local i = 1
  local ttl = MINIMUM_TTL
  log_info("Redis response", answers)
  routes[1] = answers[1]
  if answers[2] ~= ngx.null then
    ttl = answers[2]
  end
  return routes, err, ttl
end

return _M
