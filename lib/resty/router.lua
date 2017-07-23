local _M = {
    _VERSION = "0.1"
}
local mt = { __index = _M }
local setmetatable = setmetatable

local ok, shcache = pcall(require, "resty.shcache")
if not ok then
    error("lua-resty-shcache module required")
end

local ok, cjson = pcall(require, "cjson")
if not ok then
    error("cjson module required")
end

local DEBUG = ngx.config.debug
local LOG_DEBUG = ngx.DEBUG
local LOG_ERR = ngx.ERR
local LOG_INFO = ngx.INFO
local LOG_WARN = ngx.WARN

-- minimum TTL is 1 second, not 0, due to ngx.shared.DICT.set exptime
_M.MINIMUM_TTL = 1
_M.prefix = ngx.var.key_prefix
local DEFAULT_ACTUALIZE_TTL = 5
local DEFAULT_NEGATIVE_TTL = 5
local DEFAULT_POSITIVE_TTL = 5

local function log(log_level, ...)
    ngx.log(log_level, "router: " .. cjson.encode({...}))
end

function _M.log_info(...)
    log(LOG_INFO, ...)
end

function _M.log_warn(...)
    log(LOG_WARN, ...)
end

function _M.log_err(...)
    log(LOG_ERR, ...)
end

function _M.log_debug(...)
    if not DEBUG then
        return
    end
    log(LOG_DEBUG, ...)
end

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
    local lookup_route = function(key)
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
    local routes = lookup_route(key)
    if not routes or 0 == #routes then
        return nil
    end
    local route = routes[math.random(#routes)]
    self.log_info({ key = key, route = route })
    return route
end

return _M
