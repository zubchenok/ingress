--[=========================================================================[
   Lunity v0.10.1 by Gavin Kistner
   See http://github.com/Phrogz/Lunity for usage documentation.
   Licensed under Creative Commons Attribution 3.0 United States License.
   See http://creativecommons.org/licenses/by/3.0/us/ for details.
--]=========================================================================]

local setmetatable=setmetatable
local _G=_G
module( 'lunity' )

VERSION = "0.10.1"

local lunity = _M
setmetatable( lunity, {
	__index = _G,
	__call = function( self, testSuite )
		setmetatable( testSuite, {
			__index = function( testSuite, value )
				if value == 'runTests' then
					return function( options ) return lunity.__runAllTests( testSuite, options ) end
				elseif lunity[value] then
					return lunity[value]
				else
					return nil
				end
			end
		} )
	end
} )

function __assertionSucceeded()
	lunity.__assertsPassed = lunity.__assertsPassed + 1
	io.write('.')
	return true
end

function fail( msg )
	if not msg then msg = "(test failure)" end
	error( msg, 2 )
end

function assert( testCondition, msg )
	if not testCondition then
		if not msg then msg = "assert() failed: value was "..tostring(testCondition) end
		error( msg, 2 )
	end
	return __assertionSucceeded()
end

function assertEqual( actual, expected, msg )
	if actual~=expected then
		if not msg then
			msg = string.format( "assertEqual() failed: expected %s, was %s",
				tostring(expected),
				tostring(actual)
			)
		end
		error( msg, 2 )
	end
	return __assertionSucceeded()
end

function assertTableEquals( actual, expected, msg, keyPath )
	-- Easy out
	if actual == expected then
		if not keyPath then
			return __assertionSucceeded()
		else
			return true
		end
	end
	
	if not keyPath then keyPath = {} end

	if type(actual) ~= 'table' then
		if not msg then
			msg = "Value passed to assertTableEquals() was not a table."
		end			
		error( msg, 2 + #keyPath )
	end
		
	-- Ensure all keys in t1 match in t2
	for key,expectedValue in pairs( expected ) do
		keyPath[#keyPath+1] = tostring(key)
		local actualValue = actual[key]
		if type(expectedValue)=='table' then
			if type(actualValue)~='table' then
				if not msg then
					msg = "Tables not equal; expected "..table.concat(keyPath,'.').." to be a table, but was a "..type(actualValue)
				end
				error( msg, 1 + #keyPath )
			elseif expectedValue ~= actualValue then
				assertTableEquals( actualValue, expectedValue, msg, keyPath )
			end
		else
			if actualValue ~= expectedValue then
				if not msg then
					if actualValue == nil then
						msg = "Tables not equal; missing key '"..table.concat(keyPath,'.').."'."
					else
						msg = "Tables not equal; expected '"..table.concat(keyPath,'.').."' to be "..tostring(expectedValue)..", but was "..tostring(actualValue)
					end
				end			
				error( msg, 1 + #keyPath )
			end
		end
		keyPath[#keyPath] = nil
  end

	-- Ensure actual doesn't have keys that aren't expected
	for k,_ in pairs(actual) do
		if expected[k] == nil then
			if not msg then
				msg = "Tables not equal; found unexpected key '"..table.concat(keyPath,'.').."."..tostring(k).."'"
			end
			error( msg, 2 + #keyPath )
		end
	end

	return __assertionSucceeded()
end

function assertNotEqual( actual, expected, msg )
	if actual==expected then
		if not msg then
			msg = string.format( "assertNotEqual() failed: value not allowed to be %s",
				tostring(actual)
			)
		end
		error( msg, 2 )
	end
	return __assertionSucceeded()
end

function assertTrue( actual, msg )
	if actual ~= true then
		if not msg then
			msg = string.format( "assertTrue() failed: value was %s, expected true",
				tostring(actual)
			)
		end
		error( msg, 2 )
	end
	return __assertionSucceeded()
end

function assertFalse( actual, msg )
	if actual ~= false then
		if not msg then
			msg = string.format( "assertFalse() failed: value was %s, expected false",
				tostring(actual)
			)
		end
		error( msg, 2 )
	end
	return __assertionSucceeded()
end

function assertNil( actual, msg )
	if actual ~= nil then
		if not msg then
			msg = string.format( "assertNil() failed: value was %s, expected nil",
				tostring(actual)
			)
		end
		error( msg, 2 )
	end
	return __assertionSucceeded()
end

function assertNotNil( actual, msg )
	if actual == nil then
		if not msg then msg = "assertNotNil() failed: value was nil" end
		error( msg, 2 )
	end
	return __assertionSucceeded()
end

function assertType( actual, expectedType, msg )
	if type(actual) ~= expectedType then
		if not msg then
			msg = string.format( "assertType() failed: value %s is a %s, expected to be a %s",
				tostring(actual),
				type(actual),
				expectedType
			)
		end
		error( msg, 2 )
	end
	return __assertionSucceeded()
end

function assertTableEmpty( actual, msg )
	if type(actual) ~= "table" then
		msg = string.format( "assertTableEmpty() failed: expected a table, but got a %s",
			type(table)
		)
		error( msg, 2 )		
	else
		local key, value = next(actual)
		if key ~= nil then
			if not msg then
				msg = string.format( "assertTableEmpty() failed: table has non-nil key %s=%s",
					tostring(key),
					tostring(value)
				)
			end
			error( msg, 2 )
		end
		return __assertionSucceeded()
	end
end

function assertTableNotEmpty( actual, msg )
	if type(actual) ~= "table" then
		msg = string.format( "assertTableNotEmpty() failed: expected a table, but got a %s",
			type(actual)
		)
		error( msg, 2 )		
	else
		if next(actual) == nil then
			if not msg then
				msg = "assertTableNotEmpty() failed: table has no keys"
			end
			error( msg, 2 )
		end
		return __assertionSucceeded()
	end
end

function assertSameKeys( t1, t2, msg )
	local function bail(k,x,y)
		if not msg then msg = string.format("Table #%d has key '%s' not present in table #%d",x,tostring(k),y) end
		error( msg, 3 )
	end
	for k,_ in pairs(t1) do if t2[k]==nil then bail(k,1,2) end end
	for k,_ in pairs(t2) do if t1[k]==nil then bail(k,2,1) end end
	return __assertionSucceeded()
end

-- Ensures that the value is a function OR may be called as one
function assertInvokable( value, msg )
	local meta = getmetatable(value)
	if (type(value) ~= 'function') and not ( meta and meta.__call and (type(meta.__call)=='function') ) then
		if not msg then
			msg = string.format( "assertInvokable() failed: '%s' can not be called as a function",
				tostring(value)
			)
		end
		error( msg, 2 )
	end
	return __assertionSucceeded()
end

function assertErrors( invokable, ... )
	assertInvokable( invokable )
	if pcall(invokable,...) then
		local msg = string.format( "assertErrors() failed: %s did not raise an error",
			tostring(invokable)
		)
		error( msg, 2 )
	end
	return __assertionSucceeded()
end

function assertDoesNotError( invokable, ... )
	assertInvokable( invokable )
	if not pcall(invokable,...) then
		local msg = string.format( "assertDoesNotError() failed: %s raised an error",
			tostring(invokable)
		)
		error( msg, 2 )
	end
	return __assertionSucceeded()
end

function stub(t, sym, func)
    local old_func = t[sym]
    t[sym] = func
    return { unstub = function() t[sym] = old_func end }
end

function is_nil( value ) return type(value)=='nil' end
function is_boolean( value ) return type(value)=='boolean' end
function is_number( value ) return type(value)=='number' end
function is_string( value ) return type(value)=='string' end
function is_table( value ) return type(value)=='table' end
function is_function( value ) return type(value)=='function' end
function is_thread( value ) return type(value)=='thread' end
function is_userdata( value ) return type(value)=='userdata' end

function __runAllTests( testSuite, options )
	if not options then options = {} end
	lunity.__assertsPassed = 0

	local useHTML, useANSI
	if options.useHTML ~= nil then
		useHTML = options.useHTML
	else
		useHTML = lunity.useHTML
	end

	if not useHTML then
		if options.useANSI ~= nil then
			useANSI = options.useANSI
		elseif lunity.useANSI ~= nil then
			useANSI = lunity.useANSI
		else
			useANSI = true
		end
	end
	
	if useHTML then
		print( "<h2 style='background:#000; color:#fff; margin:1em 0 0 0; padding:0.1em 0.4em; font-size:120%'>"..testSuite._NAME.."</h2><pre style='margin:0; padding:0.2em 1em; background:#ffe; border:1px solid #eed; overflow:auto'>" )
	else
		print( string.rep('=',78) )
		print( testSuite._NAME )
		print( string.rep('=',78) )
	end
	io.stdout:flush()

	local theTestNames = {}
	for testName,test in pairs(testSuite) do
		if type(test)=='function' and type(testName)=='string' and (testName:find("^test") or testName:find("test$")) then
			theTestNames[#theTestNames+1] = testName
		end
	end
	table.sort(theTestNames)

	local theSuccessCount = 0
	for _,testName in ipairs(theTestNames) do
		local testScratchpad = {}
		io.write( testName..": " )
		if testSuite.setup then testSuite.setup(testScratchpad) end
		local successFlag, errorMessage = pcall( testSuite[testName], testScratchpad )
		if successFlag then
			print( "pass" )
			theSuccessCount = theSuccessCount + 1
		else
			if useANSI then
				print( "\27[31m\27[1mFAIL!\27[0m" )
				print( "\27[31m"..errorMessage.."\27[0m" )
			elseif useHTML then
				print("<b style='color:red'>FAIL!</b>")
				print( "<span style='color:red'>"..errorMessage.."</span>" )
			else
				print("FAIL!")
				print( errorMessage )
			end
		end
		io.stdout:flush()
		if testSuite.teardown then testSuite.teardown( testScratchpad ) end
	end
	if useHTML then
		print( "</pre>" )
	else
		print( string.rep( '-', 78 ) )
	end

	print( string.format( "%d/%d tests passed (%0.1f%%)",
		theSuccessCount,
		#theTestNames,
		100 * theSuccessCount / #theTestNames
	) )

	if useHTML then
		print( "<br>" )
	end

	print( string.format( "%d total successful assertion%s",
		lunity.__assertsPassed,
		lunity.__assertsPassed == 1 and "" or "s"
	) )

	if not useHTML then
		print( "" )
	end
	io.stdout:flush()

	return theSuccessCount == #theTestNames
end