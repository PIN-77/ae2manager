  
local files = {
    {path = "/home/test/ae2Class.lua", link = "https://raw.githubusercontent.com/rxi/json.lua/master/json.lua"},
}

if not filesystem.exists("/home/test") then
    filesystem.makeDirectory("/home/test")
end

for file = 1, #files do
    if not filesystem.exists(files[file].path) then
        write(files[file].path, "w", request(files[file].link))
    end
end