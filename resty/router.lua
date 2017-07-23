local _M = {}
local mt = { __index = _M }
local setmetatable = setmetatable

local ok, shcache = pcall(require, "dynx.resty.shcache")

local ok, cjson = pcall(require, "cjson")


-- minimum TTL is 1 second, not 0, due to ngx.shared.DICT.set exptime
_M.MINIMUM_TTL = 1
_M.prefix = ngx.var.key_prefix
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
      for k,v in pairs(opts_cache) do
          if opts[k] then
              opts_cache[k] = opts[k]
          end
      end
    end
    local backend_class = require(backend_name)
    local backend = backend_class:new(opts,1)
    local self = {
        backend = backend,
        opts = opts_cache,
    }
    self.lookup_route = function(key)
      local lookup = function(key)
        return self.backend:lookup(key)
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
  return self.backend:set(key, upstream, ttl)
end

function _M.unset_route(self, key)
  return self.backend:unset(key)
end

function _M.flushall(self)
  return self.backend:flushall()
end

function _M.get_route(self, key)
    local routes = self.lookup_route(key)
    if not routes or 0 == #routes then
        return nil
    end
    local route = routes[math.random(#routes)]
    return route
end

return _M
