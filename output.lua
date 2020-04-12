-- @Author: raceyu
-- @Date:   2020-04-11 14:48:40
-- @Last Modified by:   raceyu
-- @Last Modified time: 2020-04-12 12:20:26

local utils = require('utils')
local cjson = require('cjson')

local lbstats = ngx.shared.lbstats;
local metrics = lbstats:get_keys()

local query = ngx.req.get_uri_args()
local format = query.format
local key = query.key
local action = query.action

if "clear" == action then
    lbstats:flush_all()
    ngx.header['Content-Type'] = "text/plain"
    ngx.say('clear success')
else
    if 'plain' == format then
        mime = 'text/plain'
        ngx.header['Content-Type'] = mime
        for k,v in ipairs(metrics) do
            ngx.say(table.concat({v, lbstats:get(v)}, ":"))
        end
    else
        output = {}
        mime = 'application/json'
        for k,v in ipairs(metrics) do
            output = utils.format_output(utils.split(v, "|"), lbstats:get(v), output)
        end
        ngx.header['Content-Type'] = mime
        ngx.say(cjson.encode(output))
    end
end
