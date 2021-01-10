local filesystem = require('filesystem')
local internet = require("internet")  

local files = {
    {path = "/home/test/server.lua", link = "https://raw.githubusercontent.com/PIN-77/ae2manager/merge_branch/server.lua"},
    {path = "/home/test/ae2Class.lua", link = "https://raw.githubusercontent.com/PIN-77/ae2manager/merge_branch/ae2Class.lua"},
    {path = "/home/test/tools.lua", link = "https://raw.githubusercontent.com/PIN-77/ae2manager/merge_branch/tools.lua"},
    {path = "/home/test/ae2test.lua", link = "https://raw.githubusercontent.com/PIN-77/ae2manager/merge_branch/ae2test.lua"},
}



for file = 1, #files do
    path=files[file].path
    link=files[file].link
    shell.execute('rm ' .. path)
    shell.execute('wget ' .. link .. ' ' .. path)
end