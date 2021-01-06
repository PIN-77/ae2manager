local filesystem = require('filesystem')
local internet = require("internet")  

local files = {
    {path = "/home/test/server.lua", link = "https://raw.githubusercontent.com/PIN-77/ae2manager/merge_branch/server.lua"},
    {path = "/home/test/ae2Class.lua", link = "https://raw.githubusercontent.com/PIN-77/ae2manager/merge_branch/ae2Class.lua"},
    {path = "/home/test/tools.lua", link = "https://raw.githubusercontent.com/PIN-77/ae2manager/merge_branch/tools.lua"},
}

function write(path, mode, data)
    local handle = filesystem.open(path, mode)
    filesystem.write(handle, data)
    filesystem.close(handle)
end

function request(path)
    local handle, data, chunk = internet.request(path), ""

    while true do
        chunk = handle.read(math.huge)

        if chunk then
            data = data .. chunk
        else
            break
        end
    end



if not filesystem.exists("/home/test") then
    filesystem.makeDirectory("/home/test")
end

for file = 1, #files do
    if not filesystem.exists(files[file].path) then
        write(files[file].path, "w", request(files[file].link))
    end
end