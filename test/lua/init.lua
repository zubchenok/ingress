local ffi = require('ffi')
local os = ffi.os:lower()
if os == "osx" then
  nginx_lua_modules_lib = "/usr/local/lib/lua/lib"
else
  nginx_lua_modules_lib = "/usr/lib/nginx/lua/lib"
end

local cwd = io.popen("pwd"):read('*l')
package.path = cwd .. "/rootfs/etc/nginx/lua/?.lua;" ..
  cwd .. "/rootfs/etc/nginx/lua/?/?.lua;" ..
  cwd ..  "/rootfs/etc/nginx/lua/vendor/lua-resty-lock-0.07/lib/lock.lua;" ..
  cwd ..  "/rootfs/etc/nginx/lua/vendor/lua-resty-lrucache-0.07/lib/lrucache.lua;" ..
  "./lua/?.lua;./test/lua/?.lua;./test/lua/lib/?.lua;"..
  nginx_lua_modules_lib .."/?.lua;" .. package.path
package.cpath = "./test/lua/lib/_" .. os .."/?.so;" .. package.cpath

lunity = require("lunity")
ngx = require("ngx_mock")
ngx.reset()
