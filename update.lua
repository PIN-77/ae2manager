local shell = require('shell')
 

local files = {
    {path = "/home/test/ae2CLI.lua", link = "https://raw.githubusercontent.com/PIN-77/ae2manager/merge_branch/ae2CLI.lua"},
    {path = "/home/test/server.lua", link = "https://raw.githubusercontent.com/PIN-77/ae2manager/merge_branch/server.lua"},
    {path = "/home/test/terminal.cfg", link = "https://raw.githubusercontent.com/PIN-77/ae2manager/merge_branch/terminal.cfg"},
}



for file = 1, #files do
    path=files[file].path
    link=files[file].link
    shell.execute('rm ' .. path)
    shell.execute('wget ' .. link .. ' ' .. path)
end
