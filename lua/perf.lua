local math_random = math.random
local table_concat = table.concat
local new_tab = require "table.new"

-- uri_charset
local uri_charset = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ._~:/@!,;=+*-"
local uri_charset_length = #uri_charset
local uri_random_charset = {}

for i = 1, uri_charset_length do
    uri_random_charset[i] = string.sub(uri_charset, i, i)
end

local _M = {}

local function init()
    local seed = 0

    local frandom, err = io.open("/dev/urandom", "rb")
    if not frandom then
      ngx.log(ngx.WARN, 'failed to open /dev/urandom: ', err)
    else
        local str = frandom:read(4)
        frandom:close()
        if not str then
            ngx.log(ngx.WARN, 'failed to read data from /dev/urandom')
        else
            for i = 1, 4 do
                seed = 256 * seed + str:byte(i)
            end
        end
    end

    if seed == 0 then
        ngx.log(ngx.WARN, 'failed to get seed from urandom')
        seed = ngx.now() * 1000 + ngx.worker.pid()
    end

    math.randomseed(seed)
end

local function gen_body()
    local max_n = 1000
    local max_len = 20
    local body = new_tab(max_n * max_len, 0)
    
    local n = math_random(max_n)
    local idx = 0

    local gen_uri_comp = function ()
        local len = math_random(max_len)
        for _ = 1, len do
            idx = idx + 1
            body[idx] = uri_random_charset[math_random(uri_charset_length)]
        end
    end

    for i = 1, n do
        gen_uri_comp()
        idx = idx + 1
        body[idx] = "="
        gen_uri_comp()

        if i < n then
            idx = idx + 1
            body[idx] = "&"
        end
    end
    return table_concat(body, "", 1, idx)
end


local function run()
    local response = gen_body()
    ngx.say(response)
end

_M.init = init
_M.run = run
return _M
