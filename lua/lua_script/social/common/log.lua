--
--    张海  2015-05-25
--

local log = require("social.common.logadapter");

local _M ={};

local prefix = ngx.config.prefix()

log.outfile = prefix.."logs/data.log"

log.level = "debug"

return log:inherit(_M):init();

