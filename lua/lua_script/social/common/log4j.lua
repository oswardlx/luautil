--
--    张海  2015-05-25
--    描述：  一个日志实现类，用于调试输出.
--
local Log = { _VERSION = "0.2" }
local tableutil = require("social.common.table")

local prefix = ngx.config.prefix()
local filename = os.date("%Y%m%d", os.time())
local filepath = prefix .. "logs/space/"
local outfile = string.format(filepath.."%s.log", filename)
Log.level = "DEBUG"
local modes = {
    { name = "TRACE" },
    { name = "DEBUG" },
    { name = "INFO" },
    { name = "WARN" },
    { name = "ERROR" },
    { name = "FATAL" },
}

function Log:new(file)
    local self = {} --创建新的表作为实例的对象
    setmetatable(self, { __index = Log }) --设置Log为对象元表的__index
    self.outfile = file or outfile
    return self --返回该新表
end

local levels = {}
for i, v in ipairs(modes) do
    levels[v.name] = i
end
local _tostring = tostring

local tostring = function(...)
    local t = {}
    for i = 1, select('#', ...) do
        local x = select(i, ...)
        local dataType = type(x)
        if dataType == "string" then
            t[#t + 1] = string.format('%q', x)
        elseif dataType == "number" or dataType == "boolean" then
            t[#t + 1] = tostring(x)
        elseif dataType == "table" then
            t[#t + 1] = tableutil:toString(x, "\t", 1)
        else
            t[#t + 1] = "<" .. tostring(x) .. ">"
        end
    end
    return table.concat(t, " ")
end

local function writeLog(level, ...)
    if levels[level] < levels[Log.level] then
        return;
    end
    local msg = tostring(...)
    local info = debug.getinfo(3, "Sl")
    local name = string.match(info.short_src, ".+/([^/]*%.%w+)$");
    local src_name = (name == nil and "") or name
    local lineinfo = src_name .. ":" .. info.currentline
    if Log.outfile then
        local fp = io.open(Log.outfile, "a+")
        if fp==nil then
            local path = string.match(Log.outfile, "(.+)/[^/]*%.%w+$")
            os.execute('mkdir -p '..path)
            fp = io.open(Log.outfile, "a+")
        end
        local str = string.format("[%-6s%s] %s: %s\n", level, os.date(), lineinfo, msg)
        fp:write(str)
        fp:close()
    end
end


function Log:trace(...)
    Log.outfile = self.outfile
    writeLog("TRACE", ...)
end

function Log:debug(...)
    Log.outfile = self.outfile
    writeLog("DEBUG", ...)
end

function Log:info(...)
    Log.outfile = self.outfile
    writeLog("INFO", ...)
end

function Log:warn(...)
    Log.outfile = self.outfile
    writeLog("WARN", ...)
end

function Log:error(...)
    Log.outfile = self.outfile
    writeLog("ERROR", ...)
end

function Log:fatal(...)
    Log.outfile = self.outfile
    writeLog("FATAL", ...)
end

return Log
