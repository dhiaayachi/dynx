local _M = {}
local mt = { __index = _M }
local setmetatable = setmetatable

local shcache = require("dynx.resty.shcache")

local cjson = require("cjson")


-- minimum TTL is 1 second, not 0, due to ngx.shared.DICT.set exptime
_M.MINIMUM_TTL = 1
local DEFAULT_ACTUALIZE_TTL = 5
local DEFAULT_NEGATIVE_TTL = 5
local DEFAULT_POSITIVE_TTL = 5

function _M.new(self, backend_name, opts)
    local opts_cache = {
        positive_ttl = DEFAULT_POSITIVE_TTL,
        negative_ttl = DEFAULT_NEGATIVE_TTL,
        actualize_ttl = DEFAULT_ACTUALIZE_TTL,
    }
    if opts ~= nil then
      for k,_ in pairs(opts_cache) do
          if opts[k] then
              opts_cache[k] = opts[k]
          end
      end
    end
    local backend_class = require(backend_name)
    local redis  = require "resty.redis"
    local client = redis:new()
    local backend = backend_class:new(1,client)
    self.backend = backend
    self.opts = opts_cache
    self.lookup_route = function(key)
      local lookup = function(key_lookup)
        return self.backend.lookup(key_lookup,nil)
      end
      local cache = shcache:new(
        ngx.shared.cache_dict,
        {
          external_lookup = lookup,
          external_lookup_arg = key,
          encode = cjson.encode,
          decode = cjson.decode,
        },
        {
          positive_ttl = self.opts.positive_ttl,
          negative_ttl = self.opts.negative_ttl,
          actualize_ttl = self.opts.actualize_ttl,
          name = "resty_router_cache",
        }
      )
      return cache:load(key)
    end
    return setmetatable(self, mt)
end

function _M.set_route(self, key, upstream, ttl)
  return self.backend.set(key, upstream, ttl)
end

function _M.unset_route(self, key)
  return self.backend.unset(key)
end

function _M.flushall(self)
  return self.backend.flushall()
end

function _M.get_route(self, key)
    local routes,_,err = self.lookup_route(key)
    if not routes or 0 == #routes then
        return nil,err
    end
    local route = routes[math.random(#routes)]
    return route,err
end

return _M
