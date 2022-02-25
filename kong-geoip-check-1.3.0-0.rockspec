package = "kong-geoip-check"
version = "1.3.0-0"
source = {
    url = "https://github.com/elvis824/kong-geoip-check",
    tag = "v1.3.0",
    dir = "geoip-check",
}
description = {
    summary = "A Kong plugin for implementing GeoIP access list with whitelist countries, blacklist countries and whitelist cidrs.",
    detailed = [[
        kong-geoip-check is a Kong plugin for implementing GeoIP access list. It makes use of MaxMinds GeoIP database to determine originating country of a given IP address.
    ]],
    homepage = "https://github.com/elvis824/kong-geoip-check",
    license = "Apache 2.0"
}
dependencies = {
    "lua >= 5.1",
    "lua-geoip ~> 0.2-1",
    "lua-resty-iputils ~> 0.3.0-1"
}
build = {
    type = "builtin",
    modules = {
        ["kong.plugins.geoip-check.handler"] = "kong/plugins/geoip-check/handler.lua",
        ["kong.plugins.geoip-check.schema"] = "kong/plugins/geoip-check/schema.lua",
    }
}
