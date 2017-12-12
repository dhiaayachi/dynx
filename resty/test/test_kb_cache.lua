#!/usr/bin/env lua


local lu = require('luaunit')
local runner = require 'luacov.runner'
runner.tick = true
runner.init({savestepsize = 3})
jit.off()

local kv_cache = require('dynx.resty.router.kv_cache')
local memm_store = require('doubles.in_mem_kv_store')

TestKVCache = {}

function TestKVCache:setUp()
    local cl = memm_store:new(0)
    self.kv = kv_cache:new(1, cl)
end

function TestKVCache:test1_newKVCache()
    lu.assertNotEquals( self.kv, nil )
end

function TestKVCache:test2_canStoreAndLookup()
    self.kv.set('test', 'upstream', 10, "fix")
    local routes,err,ttl = self.kv.lookup("test","fix")
    lu.assertNotEquals( routes, nil )
    lu.assertEquals( routes[1], "upstream" )
    lu.assertEquals( ttl, 10 )
    lu.assertEquals( err, nil )
end

function TestKVCache:test3_canFlushAll()
    self.kv.set('test', 'upstream', 10, "fix")
    self.kv.set('test2', 'upstream2', 10, "fix")
    self.kv.set('test3', 'upstream3', 10, "fix")
    local state, err = self.kv.flushall()
    lu.assertNotEquals( state, nil )
    lu.assertEquals( err, nil )
end

function TestKVCache:test4_failFlushAll()
    local cl = memm_store:new(1)
    self.kv = kv_cache:new(1, cl)
    self.kv.set('test', 'upstream', 10, "fix")
    self.kv.set('test2', 'upstream2', 10, "fix")
    self.kv.set('test3', 'upstream3', 10, "fix")
    local state, err = self.kv.flushall()
    lu.assertEquals( state, nil )
    lu.assertNotEquals( err, nil )
end


local unit_runner = lu.LuaUnit.new()
unit_runner:setOutputType("tap")
os.exit( unit_runner:runSuite() )