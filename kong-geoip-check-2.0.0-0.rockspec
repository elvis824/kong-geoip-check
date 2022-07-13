package = "kong-geoip-check"
version = "2.0.0-0"
source = {
    url = "https://gitlab.com/elvis824/kong-geoip-check",
    tag = "v2.0.0",
    dir = "geoip-check",
}
description = {
    summary = "A Kong plugin for implementing GeoIP access list with whitelist countries, blacklist countries and whitelist cidrs.",
    detailed = [[
        kong-geoip-check is a Kong plugin for implementing GeoIP access list. It makes use of MaxMinds GeoIP database to determine originating country of a given IP address.
    ]],
    homepage = "https://gitlab.com/elvis824/kong-geoip-check",
    license = "Apache 2.0"
}
dependencies = {
    "lua >= 5.1",
    "mmdblua ~> 0.2",
    "lua-resty-iputils ~> 0.3.0-1"
}
build = {
    type = "builtin",
    modules = {
        ["kong.plugins.geoip-check.handler"] = "kong/plugins/geoip-check/handler.lua",
        ["kong.plugins.geoip-check.schema"] = "kong/plugins/geoip-check/schema.lua",
    }
}
