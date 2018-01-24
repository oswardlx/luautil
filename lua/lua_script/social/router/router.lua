--local util = require("social.common.util")
local cjson = require "cjson"
--local ssdbutil = require("social.common.ssdbutil")
--local redisutil = require("social.common.redisutil")
--local mysqlutil = require("social.common.mysqlutil");

local log = require("social.common.log")
local _M = { debug = nil }

local Application = {}

function Application:new(obj)
    obj = obj or {}
    setmetatable(obj, self)
    self.__index = self
    return obj
end

--local function clean()
--    --此处用于关闭所有的连接信息。
--    --
--    mysqlutil:clean();
--    ssdbutil:keepalive()
--    redisutil:keepalive()
--
--   -- log.debug("回收数据库连接 。")
--end

function Application:run()
    local matched = nil
    local _method = ngx.req.get_method();
--    log.debug("请求方式.");
--    log.debug(_method)
    --  log.debug(#self.urls[_method])
    for i = 1, #self.urls[_method], 2 do
        local pattern = self.urls[_method][i]
        local view = self.urls[_method][i + 1]
        -- log.debug(view)
        --  log.debug(pattern)
        --        log.debug(ngx.var.uri)
        -- regex mather in compile mode
        local match = ngx.re.match(ngx.var.uri, pattern, "")
        --        log.debug(match);
        if match then
            --log.debug(match[0]);
            if _M.debug then
                ngx.log(ngx.DEBUG, "match pattern:", pattern)
            end
            matched = i
            local status = view(unpack(match))
--            clean();
            status = status or ngx.HTTP_OK
            ngx.exit(status)
        end
    end

    if not matched then
        if _M.debug then
            ngx.log(ngx.DEBUG, "uri not matched:", ngx.var.uri)
        end
        ngx.exit(ngx.HTTP_NOT_FOUND)
    end
end

function Application:start()
    local status, err = pcall(function()
        self:run()
    end)
    if not status then
        local res = {}
        res.success = false;
        res.info = err;
        ngx.print(cjson.encode(res))
    end
end

function _M.application(urls, env)
    local app = Application:new { urls = urls }
    return app
end



return _M

