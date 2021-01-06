  
local files = {
    {path = "/home/test/server.lua", link = "https://raw.githubusercontent.com/PIN-77/ae2manager/merge_branch/server.lua"},
    {path = "/home/test/ae2Class.lua", link = "https://raw.githubusercontent.com/PIN-77/ae2manager/merge_branch/ae2Class.lua"},
    {path = "/home/test/tools.lua", link = "https://raw.githubusercontent.com/PIN-77/ae2manager/merge_branch/tools.lua"},
}

if not filesystem.exists("/home/test") then
    filesystem.makeDirectory("/home/test")
end

for file = 1, #files do
    if not filesystem.exists(files[file].path) then
        write(files[file].path, "w", request(files[file].link))
    end
end