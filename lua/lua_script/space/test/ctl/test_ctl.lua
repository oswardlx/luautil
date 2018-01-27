--
-- Created by IntelliJ IDEA.
-- User: 91946
-- Date: 2018/1/22
-- Time: 13:30
-- To change this template use File | Settings | File Templates.
--
local web = require("social.router.router")
local request = require("social.common.request")
local permission_context = ngx.var.path_uri --有权限的context.
local permission_no_context = ngx.var.path_uri_no_permission
local cjson = require "cjson"
local prefix = ngx.config.prefix()
local filename = os.date("os%Y%m%d", os.time())
local filepath = prefix .. "logs/space/"
local mylog = string.format(filepath .. "%s.log", filename)
local log = require("social.common.log4j"):new(mylog)
--local function get

local function demo1()
    local redballs ={}
    local redball
    for k=1,6 do
        redball = request:getNumParam(string.format("redball%s",k),true,true)
        redballs[k]=redball
    end
    log:debug(redballs)
    log:debug(123123)
    ngx.say(121212121)
    return;

end

local urls = {
    GET = {
                permission_no_context..'/demo1',demo1,

    },
    POST = {
        --        management_context .. '/delete_boutique_lead$', deleteBoutiqueLead, --删除精品导学.

    }
}
local app = web.application(urls, nil)
app:start()