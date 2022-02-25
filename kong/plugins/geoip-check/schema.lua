local typedefs = require "kong.db.schema.typedefs"

-- Grab pluginname from module name
local plugin_name = ({...})[1]:match("^kong%.plugins%.([^%.]+)")

local whitelist_countries_array = {
    type = "array",
    default = {},
    elements = {
        type = "string",
    },
}

local blacklist_countries_array = {
    type = "array",
    default = {},
    elements = {
        type = "string",
    },
}

local whitelist_cidrs_array = {
    type = "array",
    default = {},
    elements = {
        type = "string",
    },
}

return {
    name = plugin_name,
    fields = {
        { consumer = typedefs.no_consumer },
        { config = {
            type = "record",
            fields = {
                { whitelist_countries = whitelist_countries_array },
                { blacklist_countries = blacklist_countries_array },
                { whitelist_cidrs = whitelist_cidrs_array },
            }
        }},
    },
    entity_checks = {
    },
}