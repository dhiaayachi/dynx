local _M = {}
local mt = { __index = _M }
local setmetatable = setmetatable
local cjson = require("cjson")

function _M:connect(addr, port)
    self.kv_store = {}
    self.addr = addr
    self.port = port
end


function _M:new(fail)
    self.fail = fail
    return setmetatable(self, mt)
end

function _M:set_fail(fail)
    self.fail = fail
end

function _M:select(index)
    if self.fail == 4 then
        return nil, {}
    end
    if self.kv_store[index] == nil then
        self.kv_store[index] = {}
    end
    self.index = index
    return {}, nil
end

function _M:hmset(prefix_key,upstream_name,upstream,ttl_name,ttl)
    if self.kv_store[self.index] == nil then
        self.kv_store[self.index] = {}
    end
    self.kv_store[self.index][prefix_key] = {}
    self.kv_store[self.index][prefix_key][upstream_name] = upstream
    self.kv_store[self.index][prefix_key][ttl_name] = ttl;

    return {},nil
end

function _M:hmget(prefix_key,upstream_name,ttl_name)
    return {self.kv_store[self.index][prefix_key][upstream_name],self.kv_store[self.index][prefix_key][ttl_name]}
end

function _M:hdel(prefix_key,name)
    if self.fail == 5 then
        return nil, {}
    end
    if self.fail == 6 then
        self.fail = 5
    end
    self.kv_store[self.index][prefix_key][name] = nil
    if next(self.kv_store[self.index][prefix_key]) == nil then
        self.kv_store[self.index][prefix_key] = nil
    end
    return {},nil
end
function _M:set_timeout(time)
    self.timeout = time
end

function _M:flushdb()
    if self.fail == 1 then
        return nil, {}
    end
    self.kv_store[self.index] = nil
    return {},nil
end

function _M:multi()
    if self.fail == 2 then
        return nil, {}
    else
        return {},nil
    end
end

function _M:exec()
    if self.fail == 3 then
        return nil, {}
    else
        return {},nil
    end
end


return _M