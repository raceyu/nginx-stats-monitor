-- @Author: raceyu
-- @Date:   2020-04-11 14:33:33
-- @Last Modified by:   raceyu
-- @Last Modified time: 2020-04-11 21:40:51

local utils = require('utils')

local lbstats = ngx.shared.lbstats
local collect_key = ngx.var.req_status_key
local req_location = ngx.var.req_location

local sep = "|"

function req_status(collect_key)
    -- requests
    utils.myincr(lbstats, utils.join({collect_key, "requests_total"}, sep))

    -- rt
    local request_time = tonumber(ngx.var.request_time) or 0
    utils.myincr(lbstats, utils.join({collect_key, "request_time"}, sep), request_time)

    -- upstream time
    -- proxy_next_upstream will upstream retry
    local upstream_time = ngx.var.upstream_response_time
    upstream_retries = 0
    if nil == upstream_time then
        upstream_time = 0
    else
        upstream_time = 0
        for k, v in pairs(utils.split(upstream_time, ", ")) do
            upstream_time = upstream_time + (tonumber(v) or 0)
            if k > 1 then
                upstream_retries = upstream_retries + 1
            end
        end
    end
    utils.myincr(lbstats, utils.join({collect_key, "upstream_time"}, sep), upstream_time)
    utils.myincr(lbstats, utils.join({collect_key, "upstream_retries"}, sep), upstream_retries)

    -- bit_in
    utils.myincr(lbstats, utils.join({collect_key, "bits_in"}, sep), tonumber(ngx.var.request_length)*8 or 0)

    -- bit_out
    utils.myincr(lbstats, utils.join({collect_key, "bits_out"}, sep), tonumber(ngx.var.bytes_sent)*8 or 0)

    -- status
    local status = ngx.status
    utils.myincr(lbstats, utils.join({collect_key, "status", tostring(status)}, sep), 1)
    status_number = tonumber(status)

    if status_number >= 100 and status_number < 200 then
        utils.myincr(lbstats, utils.join({collect_key, "status", "1xx"}, sep), 1)
    elseif status_number >= 200 and status_number < 300 then
        utils.myincr(lbstats, utils.join({collect_key, "status", "2xx"}, sep), 1)
    elseif status_number >= 300 and status_number < 400 then
        utils.myincr(lbstats, utils.join({collect_key, "status", "3xx"}, sep), 1)
    elseif status_number >= 400 and status_number < 500 then
        utils.myincr(lbstats, utils.join({collect_key, "status", "4xx"}, sep), 1)
    else
        utils.myincr(lbstats, utils.join({collect_key, "status", "5xx"}, sep), 1)
    end

    local upstream_addr = ngx.var.upstream_addr
    local upstream_status = ngx.var.upstream_status

    if upstream_status ~= nil then
        upstream_addr_list = utils.split(upstream_addr, ", ")
        for k, v in pairs(utils.split(upstream_status, ", ")) do
            utils.myincr(lbstats, utils.join({collect_key, "upstream", "requests_total"}, sep), 1)
            utils.myincr(lbstats, utils.join({collect_key, "upstream", tostring(v)}, sep), 1)
            ups_status_num = tonumber(v)
            if ups_status_num >= 100 and ups_status_num < 200 then
                utils.myincr(lbstats, utils.join({collect_key, "upstream", "1xx"}, sep), 1)
            elseif ups_status_num >= 200 and ups_status_num < 300 then
                utils.myincr(lbstats, utils.join({collect_key, "upstream", "2xx"}, sep), 1)
            elseif ups_status_num >= 300 and ups_status_num < 400 then
                utils.myincr(lbstats, utils.join({collect_key, "upstream", "3xx"}, sep), 1)
            elseif ups_status_num >= 400 and ups_status_num < 500 then
                utils.myincr(lbstats, utils.join({collect_key, "upstream", "servers", upstream_addr_list[k], "4xx"}, sep), 1)
                utils.myincr(lbstats, utils.join({collect_key, "upstream", "4xx"}, sep), 1)
            else
                utils.myincr(lbstats, utils.join({collect_key, "upstream", "servers", upstream_addr_list[k], "5xx"}, sep), 1)
                utils.myincr(lbstats, utils.join({collect_key, "upstream", "5xx"}, sep), 1)
            end
        end
    end
end

if collect_key == nil or collect_key == "" then
    collect_key = ngx.var.server_name
end

req_status(collect_key)

if req_location ~= nil and req_location ~= "" then
    collect_key = utils.join({collect_key, req_location}, "__")
    req_status(collect_key)
end
