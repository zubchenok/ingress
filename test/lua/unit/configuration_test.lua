local cwd = io.popen("pwd"):read('*l')
package.path = cwd .. "/test/lua/?.lua;" ..package.path

require("helpers.init")

module("configuration_tests", lunity)

local configuration = require("configuration")

function setup()
  ngx.reset()
end

function test_call_bad_method()
  ngx.var.request_method = "DELETE"
  configuration.call()

  lunity.assertEqual(ngx.printed, "Only POST and GET requests are allowed!", "nginx print")
  lunity.assertEqual(ngx.status, ngx.HTTP_BAD_REQUEST, "nginx status")
end

function test_call_bad_uri()
  ngx.var.request_uri = "/bad/uri"
  configuration.call()

  lunity.assertEqual(ngx.printed, "Not found!", "nginx print")
  lunity.assertEqual(ngx.status, ngx.HTTP_NOT_FOUND, "nginx status")
end

function test_call_get()
  ngx.var.request_uri = "/configuration/backends"
  ngx.var.request_method = "GET"

  configuration.call()
  lunity.assertEqual(ngx.status, ngx.HTTP_OK, "nginx status")
end

function test_call_post()
  ngx.var.request_uri = "/configuration/backends"
  ngx.var.request_method = "POST"

  configuration.call()
  lunity.assertEqual(ngx.status, ngx.HTTP_CREATED, "nginx status")
end

os.exit(runTests() and 0 or 1)