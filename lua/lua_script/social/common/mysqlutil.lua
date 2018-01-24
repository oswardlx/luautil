--
-- Created by IntelliJ IDEA.
-- User: zhanghai
-- Date: 2016/1/9 0009
-- Time: 下午 3:48
-- To change this template use File | Settings | File Templates.
--
local mysql = require("resty.mysql")
local MySQL = {}


local TIMEOUT = 15000;
--- 初始化连接
--
-- @return resty.mysql MySQL连接
function MySQL:initClient()
    local client, err = mysql:new();
    if not client then
        error(err)
    end
    client:set_timeout(TIMEOUT) --1秒.
    local options = {
        user = v_mysql_user,
        password = v_mysql_password,
        database = v_mysql_database,
        host = v_mysql_ip,
        port = v_mysql_port
    }
    local result, errmsg, errno, sqlstate = client:connect(options)
    if not result then
        error("连接数据库出错.")
    end
    ngx.ctx[MySQL] = client
    return ngx.ctx[MySQL]
end

--- 获取连接
--
-- @return resty.mysql MySQL连接
function MySQL:getDb()
    return ngx.ctx[MySQL] or self:initClient()
end

function MySQL:querySingleSql(sql)
    local db = self:getDb();
    local queryResult, err, errno, sqlstate = db:query(sql);
    if not queryResult or queryResult == nil then
        ngx.log(ngx.ERR, "[zh_log]->[DBUtil]-> sql语句执行出错：[err]-> [", err, "], [errno]-> [", errno, "], [sqlstate]->[", sqlstate, "]");
        self:clean();
        return false;
    end
    self:clean();

    return queryResult;
end

--- 回收mysql,清空ctx.
function MySQL:clean()
    --- 关闭连接
    if ngx.ctx[MySQL] then
        ngx.ctx[MySQL]:set_keepalive(TIMEOUT, v_pool_size)
        ngx.ctx[MySQL] = nil
    end
end


function MySQL:batchExecuteSqlInTx(sqlTable, pSize)
    local sql = "START TRANSACTION;";
    if sqlTable ~= nil and #sqlTable > 0 then

        local db = self:getDb();

        ngx.log(ngx.ERR, "[sj_log]->[DBUtil]-> 批量执行sql语句 ===> ");
        local batchFlag = 0;
        for i = 1, #sqlTable do

            sql = sql .. sqlTable[i];
            batchFlag = batchFlag + 1;

            ngx.log(ngx.ERR, "[sj_log]->[DBUtil]-> 第", i, "条SQL语句 ===> ", sqlTable[i]);
            if batchFlag == pSize or i == #sqlTable then
                sql = sql .. "COMMIT;";
                ngx.log(ngx.ERR, "[sj_log]->[DBUtil]-> 批量提交的SQL语句 ===> ", sql);
                local res, err, errno, sqlstate = db:query(sql)
                if not res then
                    ngx.log(ngx.ERR, "[sj_log]->[DBUtil]-> sql执行出错， 错误信息：err -> [", err, "], errno -> [", errno, "], sqlstate -> [", sqlstate, "].");
                    return false;
                end

                -- 因为是多个返回值，需要一直读取完成，否则不能返回到连接池
                while err == "again" do
                    res, err, errno, sqlstate = db:read_result()
                    if not res then
                        ngx.log(ngx.ERR, "[sj_log]->[DBUtil]-> sql执行出错， 错误信息：err -> [", err, "], errno -> [", errno, "], sqlstate -> [", sqlstate, "].");
                        return false;
                    end
                end

                batchFlag = 0;
                sql = "START TRANSACTION;";
            end
        end
        -- 将数据库连接返回连接池
        --self: keepDbAlive(db);
    end
    return true;
end

--执行sql实现事务管理
--参数为一个function.
--
function MySQL:batchExecuteSqlFunctionTx(func)
    if not func or type(func) ~= "function" then
        error("参数不是一个function.")
    end
    local db = self:getDb();
    db:query("START TRANSACTION;");
    local status, err = pcall(function()
        func()
    end)
    if status then
        db:query("COMMIT;")
    else
        db:query("ROLLBACK;")
        return false;
    end
    return true;
end

return MySQL;