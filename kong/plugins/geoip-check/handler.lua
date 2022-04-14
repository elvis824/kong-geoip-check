local base_plugin = require "kong.plugins.base_plugin"
local GeoIpHandler = base_plugin:extend()
local geoip_module = require "geoip"
local geoip_country = require "geoip.country"
local iputils = require "resty.iputils"

local geoip_country_filename = "/usr/share/GeoIP/GeoIP.dat"
local country_code_header_name = "X-Country-Code"
local eligible_header_name = "X-Eligible"

local kong = kong
local ngx = ngx

-- Grab pluginname from module name
local plugin_name = ({...})[1]:match("^kong%.plugins%.([^%.]+)")
-- GeoIP database resource
local geoip_db = nil
-- Local cache
local geoip_cache = {}
-- Cache TTL (24 hours in seconds)
local ttl = 86400

local function ip2long(ip_addr)
    local o1,o2,o3,o4 = ip_addr:match("(%d+)%.(%d+)%.(%d+)%.(%d+)")
    return 2^24*o1 + 2^16*o2 + 2^8*o3 + o4
end

local function fetch_cache(ip_addr_num)
    -- country_code, ttl
    local result = geoip_cache[ip_addr_num]
    if result == nil or result[2] < os.time() then
        return nil
    end
    return result
end

local function store_cache(ip_addr_num, country_code)
    -- country_code, ttl
    geoip_cache[ip_addr_num] = {country_code, os.time() + ttl}
end

local function array_contains(arr, target)
    for idx, value in ipairs(arr) do
        if value == target then
            return true
        end
    end
    return false
end

local function check_country_code(country_code, blacklist_country_codes_soft, blacklist_country_codes_hard, whitelist_country_codes, allow_non_whitelist_passthrough) 
    local is_allowed, is_eligible
    -- whitelist takes precedence, use blacklist only when whitelist is empty
    if # whitelist_country_codes == 0 then
        if array_contains(blacklist_country_codes_hard, country_code) then
            is_allowed = false
            is_eligible = false
        elseif array_contains(blacklist_country_codes_soft, country_code) then
            is_allowed = true
            is_eligible = false
        else 
            is_allowed = true
            is_eligible = true
        end
    else
        is_eligible = array_contains(whitelist_country_codes, country_code)
        is_allowed = is_eligible or allow_non_whitelist_passthrough
    end
    return is_allowed, is_eligible
end

local function check_cidr(ip_addr, whitelist_cidrs)
    local parsed_cidrs = iputils.parse_cidrs(whitelist_cidrs)
    local result = #parsed_cidrs > 0 and iputils.ip_in_cidrs(ip_addr, parsed_cidrs)
    if result then
        kong.log.info("geoip-check: IP ", ip_addr, " allowed with whitelisted CIDRs")
    end
    return result
end

local function get_country_from_ip(ip_addr)
    local ip_addr_num = ip2long(ip_addr)
    local result = fetch_cache(ip_addr_num)
    local country_code

    if result == nil then
        kong.log.debug("geoip-check: IP ", ip_addr_num, " not found in cache")
        
        country_code = geoip_db:query_by_ipnum(ip_addr_num).code
        store_cache(ip_addr_num, country_code)
        kong.log.info("geoip-check: resolved country_code=", country_code)
    else
        kong.log.debug("geoip-check: IP ", ip_addr_num, " found in cache, country_code=", result[1])
        country_code = result[1]
    end
    return country_code
end

function GeoIpHandler:new()
    GeoIpHandler.super.new(self, plugin_name)
    kong.log.info("geoip-check: creating handler")

    -- initialize database
    geoip_db = geoip_country.open(geoip_country_filename)
end

function GeoIpHandler:access(config)
    GeoIpHandler.super.access(self)

    local req_headers = kong.request.get_headers()
    local country_code = req_headers[country_code_header_name]
    if country_code == nil then
        country_code = get_country_from_ip(ngx.var.remote_addr)
    end

    local is_allowed, is_eligible = check_country_code(country_code, config.blacklist_countries_soft, config.blacklist_countries_hard, config.whitelist_countries, config.allow_non_whitelist_passthrough)
    if not is_allowed and check_cidr(ngx.var.remote_addr, config.whitelist_cidrs) then
        is_allowed = true
        is_eligible = true
    end

    if is_allowed then
        kong.response.set_header(country_code_header_name, country_code)
        kong.response.set_header(eligible_header_name, is_eligible and "true" or "false")
        ngx.req.set_header(country_code_header_name, country_code)
        ngx.req.set_header(eligible_header_name, is_eligible and "true" or "false")
    else
        ngx.status = 403
        ngx.say("Forbidden in originating region")
        ngx.exit(ngx.HTTP_FORBIDDEN)
    end
end

GeoIpHandler.PRIORITY = 1010

return GeoIpHandler