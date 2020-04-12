# nginx-stats-monitor

Collect nginx stats with nginx lua

## Installation

1. Install [nginx](http://nginx.org/) lua module [--add-module=/path/addon/lua-nginx-module](https://github.com/openresty/lua-nginx-module) or use [OpenResty](https://openresty.org)
2. Clone [nginx-stat-monitor](https://github.com/raceyu/nginx-stat-monitor) in lua package path, specified by ```lua_package_path``` policy

```sh
cd /usr/local/nginx/lua/
git clone https://github.com/raceyu/nginx-stat-monitor.git reqstatus
```

## Overview

1. Collect statistics for requests across ```reqstatus/status.lua```, specified by ```log_by_lua_file '/usr/local/nginx/lua/reqstatus/status.lua';``` directive.
2. Show statistics metrics across location with ```content_by_lua_file /usr/local/nginx/lua/reqstatus/output.lua```

## Configure:

1) 共享内存: lua_shared_dict lbstats 10m;  # 共享内存名称硬编码了 "lbstats"
2) 采集：server 配置块中设置变量 ```set $req_status_key "x1.xxtest.com";``` 作为采集的key,不设置默认为```ngx.var.server_name```
3) 输出: 
```
location /req-status {
    content_by_lua_file reqstatus/output.lua;
}```

```Api: http://127.0.0.1/req-status```
```Clear: http://127.0.0.1/req-status?action=clear```

4) Example
```nginx
user www-data;
worker_processes  auto;
error_log  /var/log/nginx/error.log error;
pid        /var/run/nginx.pid;
events {
    worker_connections  65536;
}

http {

    lua_shared_dict lbstats 10m;
    lua_package_path '/usr/local/nginx/lua/?.lua;;';
    lua_package_cpath '/usr/local/nginx/lua/?.so;;';

    server {
        listen 80;
        server_name .x.test.com x1.xxtest.com;
        set $req_status_key "x1.xxtest.com";
        log_by_lua_file /usr/local/nginx/lua/reqstatus/status.lua;
        location / {
            return 200 "In x1.xxtest /";
        }
        location ~ /v1/(list|check|submit) {
            set $req_location "/v1";
            log_by_lua_file /usr/local/nginx/lua/reqstatus/status.lua;
            return 200 "In x1.xxtest v1 api";
        }
    }
    server {
        listen 80;
        server_name *.example.com x3.xxtest.com;
        log_by_lua_file /usr/local/nginx/lua/reqstatus/status.lua;
        location / {
            proxy_pass http://x3-xxtest;
        }
    }
    server {
        listen 80 default_server;
        server_name  _;

        location / {
            deny all;
        }
        location /server-status {
            stub_status on;
            allow 127.0.0.1/32;
            deny all;
        }
        location /req-status {
            allow 127.0.0.1/32;
            deny all;
            content_by_lua_file /usr/local/nginx/lua/reqstatus/output.lua;
        }
    }

    ## upstream
    upstream x3-xxtest {
        server 127.0.0.1:18101;
        server 127.0.0.1:18102;
        server 127.0.0.1:18103;
    }
}

```
## Result

```json
{
   "*.example.com" : { # 没有配置 req_status_key默认使用server_name
      "upstream" : {
         "requests_total" : 4,
         "5xx" : 2,
         "504" : 1,
         "200" : 2,
         "2xx" : 2,
         "502" : 1,
         "servers" : {   # 只记录了4xx和5xx的状态
            "172.0.0.1:18103" : {
               "5xx" : 1
            },
            "127.0.0.1:18101" : {
               "5xx" : 1
            }
         }
      },
      "bits_in" : 471,
      "request_time" : 11.304,
      "requests_total" : 6,
      "bits_out" : 922,
      "upstream_time" : 0,
      "upstream_retries" : 0,
      "status" : {
         "2xx" : 6,
         "200" : 6
      }
   },
   "x1.xxtest.com" : {
      "requests_total" : 3,
      "request_time" : 0,
      "bits_in" : 231,
      "bits_out" : 477,
      "upstream_time" : 0,
      "upstream_retries" : 0,
      "status" : {
         "200" : 3,
         "2xx" : 3
      }
   }
}
```