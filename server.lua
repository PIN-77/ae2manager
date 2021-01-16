local component = require("component")
local event = require("event")
local unicode = require("unicode")
local filesystem = require("filesystem")
local serialization = require("serialization")
local ae2CLI = require('ae2CLI')


local modem = component.modem
local port = 2828
local password = '1234'
local terminals = loadTerminals()

local ae2 = ae2CLI.initAe2()
ae2CLI.loadRecipes()
--for terminal = 1, #terminals do 
--    terminals[terminals[terminal]], terminals[terminal] = true, nil
--end 

local function loadTerminals():
    if checkCfgFile('/home/terminals.cfg') then
        local f = io.open('/home/terminals.cfg','r')
        local terms = serialization.unserialize(file:read())
        file:close()
    else
        local terms = {}
    end
    return terms
end
    
local function registerTerminal(address)
	local f = io.open('/home/terminals.cfg','w')
	terminals[address] = true
	f:write(serialization.serialize(terminals))
    file:close()
end

local function checkCfgFile(path)
	if not filesystem.exists(path) then
        local f=io.open(path,'w')
        file:close()
        return false
    else 
        return true
    end
end

local function getTime(type)
	local file = io.open("/tmp/time", "w")
	file:write("time")
	file:close() 
	local timestamp = filesystem.lastModified("/tmp/time") / 1000 + 3600 * 3

	if type == "full" then
		return os.date("%d.%m.%Y %H:%M:%S", timestamp)
	elseif type == "log" then
		return os.date("[%H:%M:%S] ", timestamp)
	elseif type == "filesystem" then
		return os.date("%d.%m.%Y", timestamp)
	elseif type == "raw" then
		return timestamp
	end
end

local function log(data, customPath)
	local timestamp = getTime("raw")
	local time = os.date("[%H:%M:%S] ", timestamp)
	local date = os.date("%d.%m.%Y", timestamp)
	checkPath("/home/logs/")
	local path = "/home/logs/" .. os.date("%d.%m.%Y", timestamp)
	checkPath(path)
	local data = time .. data

	if customPath then
		path = path .. customPath
	else
		path = path .. "/main.log"
	end
	local days = {date .. "/", os.date("%d.%m.%Y/", timestamp - 86400), os.date("%d.%m.%Y/", timestamp - 172800), os.date("%d.%m.%Y/", timestamp - 259200)}
    for day = 1, #days do 
        days[days[day]], days[day] = true, nil
    end
    for path in filesystem.list("/home/logs/") do 
        local checkPath = "/home/logs/" .. path
        if not days[path] then
            filesystem.remove(checkPath)
        end
    end

	local file = io.open(path, "a")
	file:write(data .. "\n")
	file:close()
end

local function send(address, data)
	modem.send(address, port, data)
end

local function responseHandler(data, address)
	log("DATA " .. data)
	local userdata, err = serialization.unserialize(data)

	if userdata then
		if terminals[address] then
			if userdata.log then
				if userdata.log.mPath and userdata.log.data then
					log(userdata.log.data, userdata.log.mPath)
				end
			end

		    if userdata.method then
		    		if userdata.method == "login" then
		    			local success = login(userdata.name, userdata.server)
		    			if success then
		    				local responseMessage = {
		    					code = 200,
		    					message = "Login successfully",
		    					userdata = success,
		    					feedbacks = readFeedbacks()	
		    				}
		    				send(address, serialization.serialize(responseMessage))
		    			else
		    				send(address, '{code = 500, message = "Unable to login, unexpected error"}')
		    			end
		    		elseif userdata.method == "merge" then
		    			if userdata.toMerge then
		    				updateUser(userdata.name, userdata.toMerge)
		    				send(address, '{code = 200, message = "Merged successfully"}')
		    			else
		    				send(address, '{code = 422, message = "toMerge is nil"}')
						end
					elseif userdata.method == "getRecipes" then
						ae2CLI.updateRecipes(true)
						local responseMessage={
							code = 200,
							message = 'Update successfully',
							recipes = recipes
						}
						send(address,serialization.serialize(responseMessage))
					
		    		else
		    			send(address, '{code = 422, message = "Bad method"}')
		    		end
		    else
		    	send(address, '{code = 422, message = "Bad method"}')
            end
		elseif userdata.method == 'register' then
			if not userdata.pw==password then
				send(address,'{code = 401, message = "Unauthorized"}')
				local logData = "Auth attempt! " .. serialization.serialize(userdata)
				log(logData)
			else
				registerTerminal(address)
				log('Registered: ' .. address)
			end
		else
			send(address, '{code = 422, message = "This modem is not whitelisted"}')
			local logData = "Access attempt! " .. serialization.serialize(userdata)
			log(logData)
        end
        
	elseif err then
		log("Unable to parse table, err: " .. err)
	end
end

local function messageHandler(event, _, address, rport, _, data)
	if port == rport then 
		responseHandler(data, address) 
	end
end

function start()
	if ripmarketIsRunning then
		io.stderr:write("Daemon is running!")
	else
		ripmarketIsRunning = true
		if modem.isOpen(port) then
			io.stderr:write("Port " .. port .. " is busy!")
		else
			if modem.open(port) then
				local success = "RipMarket started on port " .. port .. "!"
				print(success)
				log(success)
				event.listen("modem_message", messageHandler)
			else
				io.stderr:write("Unable to open port " .. port)
			end
		end
	end
end

function stop()
	if not ripmarketIsRunning then
		io.stderr:write("Daemon already stopped!")
	else
		ripmarketIsRunning = false
		modem.close(port)
		event.ignore("modem_message", messageHandler)
		print("Daemon is offline...")
		return true
	end
end

function restart()
	if stop() then
		start()
	end
end