local _M = {}
local mt = { __index = _M }
local setmetatable = setmetatable

local cjson = require("cjson")

local router = require "dynx.resty.router"
local MINIMUM_TTL = router.MINIMUM_TTL
local DEFAULT_PREFIX = "resty_route:"
local client = nil

local function log(log_level, ...)
  ngx.log(log_level, "router: " .. cjson.encode({...}))
end

function _M.new(self, index)
  local redis  = require "resty.redis"
  client = redis:new()
  client:set_timeout(1000)
  local _, _ = client:connect("redis-dyn", 6379)
  client:select(index)
  return setmetatable(self, mt)
end

function _M.set(key, upstream, ttl, Rprefix)
  local prefix = DEFAULT_PREFIX
  if Rprefix ~= nil then
    prefix = Rprefix
  end
  local prefix_key = prefix..key
  log(ngx.INFO,"key:", prefix..key)
  local res, err  = client:hmset(prefix_key,"upstream",upstream,"ttl",ttl)
  log(ngx.INFO,"res:", res,"err:",err,"p:",prefix_key,"u:",upstream,"t",ttl)
  if not res or res == ngx.null then
    return nil, cjson.encode({"Redis api not configured ofr", prefix_key, err})
  end
  return res, nil
end

function _M.unset(key,Rprefix)
  local prefix = DEFAULT_PREFIX
  if Rprefix ~= nil then
    prefix = Rprefix
  end
  local prefix_key = prefix..key
  log(ngx.INFO,"key:", prefix..key)
  local res, err = client:multi()
  if not res then
    return nil, cjson.encode({"Redis api not configured 0 for", prefix_key, err})
  end
  res, err  = client:hdel(prefix_key,"upstream")
  log(ngx.INFO,"res:", res,"err:",err)
  if not res or res == ngx.null then
    return nil, cjson.encode({"Redis api not configured 1 for", prefix_key, err})
  end
  res, err  = client:hdel(prefix_key,"ttl")
  log(ngx.INFO,"res:", res,"err:",err)
  if not res or res == ngx.null then
    return nil, cjson.encode({"Redis api not configured 2 for", prefix_key, err})
  end
  res, err = client:exec()
  if not res or res == ngx.null then
    return nil, cjson.encode({"Redis api not configured 3 for", prefix_key, err})
  end
  return cjson.encode(res), nil
end

function _M.flushall()
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

function _M.lookup(key, Rprefix)
  local prefix = DEFAULT_PREFIX
  if Rprefix ~= nil then
    prefix = Rprefix
  end
  local prefix_key = prefix..key
  log(ngx.INFO,"key:", prefix..key)
  local answers, err  = client:hmget(prefix_key,"upstream","ttl")
  if not answers or #answers ~= 2 then
    log(ngx.INFO,"1 - ans:", answers,"err:",err)
    return nil, cjson.encode({"Redis query failure", prefix_key, err}), nil
  end
  if answers[1] == ngx.null then
    log(ngx.INFO,"2 - ans:", answers,"err:",err)
    return nil, nil, nil
  end

  local routes = {}
  local ttl = MINIMUM_TTL
  log(ngx.INFO,"Redis response", answers)
  routes[1] = answers[1]
  if answers[2] ~= ngx.null then
    ttl = answers[2]
  end
  log(ngx.INFO,"3 - ans:", routes,"err:",err)
  return routes, err, ttl
end

return _M
