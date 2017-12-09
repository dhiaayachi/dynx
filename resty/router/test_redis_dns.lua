require('luaunit')

test_kv_cache = {}

function test_kv_cache:testNewSuccess()
    a = 1
    b = 2
    result = my_super_function( a, b )
    assertEquals( type(result), 'number' )
    assertEquals( result, 3 )
end

