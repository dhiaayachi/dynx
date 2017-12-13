#!/usr/bin/env lua


local lu = require('luaunit')
local runner = require 'luacov.runner'
local cjson = require 'cjson'
runner.tick = true
runner.init({savestepsize = 3})
jit.off()

local kv_cache = require('dynx.resty.router.kv_cache')
local shcache = require('dynx.resty.shcache')
local memm_store = require('doubles.in_mem_kv_store')

TESTSHCache = {}

function TESTSHCache:setUp()
    local cl = memm_store:new(0)
    self.kv = kv_cache:new(1, cl)
    self.positive_ttl = 1
    self.negative_ttl = 1
    self.actualize_ttl = 1

end

function TESTSHCache:test1_newSHCache()
    local lookup = function(key_lookup)
        return self.kv.lookup(key_lookup,nil)
    end
    local cache, err = shcache:new(
        {},
        {
            external_lookup = lookup,
            external_lookup_arg = key,
            encode = cjson.encode,
            decode = cjson.decode,
        },
        {
            positive_ttl = self.positive_ttl,
            negative_ttl = self.negative_ttl,
            actualize_ttl = self.actualize_ttl,
            name = "resty_router_cache",
            disable_check_locks = true,
        }
    )
    lu.assertNotEquals(cache, nil )
    cache, err = shcache:new(
        {},
        {
            external_lookup = lookup,
            external_lookup_arg = key,
            encode = cjson.encode,
            decode = cjson.decode,
        },
        {
            positive_ttl = self.positive_ttl,
            negative_ttl = self.negative_ttl,
            actualize_ttl = self.actualize_ttl,
            name = "resty_router_cache",
        }
    )
    lu.assertEquals(cache, nil )

    cache, err = shcache:new(
        nil,
        {
            external_lookup = lookup,
            external_lookup_arg = key,
            encode = cjson.encode,
            decode = cjson.decode,
        },
        {
            positive_ttl = self.positive_ttl,
            negative_ttl = self.negative_ttl,
            actualize_ttl = self.actualize_ttl,
            name = "resty_router_cache",
        }
    )
    lu.assertEquals(cache, nil )
end

--function TESTSHCache:test2_retrieveFromCache()
--    local lookup = function(key_lookup)
--        return self.kv.lookup(key_lookup,nil)
--    end
--    local cache, _ = shcache:new(
--        {},
--        {
--            external_lookup = lookup,
--            external_lookup_arg = key,
--            encode = cjson.encode,
--            decode = cjson.decode,
--        },
--        {
--            positive_ttl = self.positive_ttl,
--            negative_ttl = self.negative_ttl,
--            actualize_ttl = self.actualize_ttl,
--            name = "resty_router_cache",
--            disable_check_locks = true,
--        }
--    )
--    self.kv.set('test', 'upstream', 10, nil)
--    lu.assertNotEquals(cache, nil )
--    lu.assertNotEquals(cache:load('test'),'upstream')
--end

local unit_runner = lu.LuaUnit.new()
unit_runner:setOutputType("tap")
os.exit( unit_runner:runSuite() )