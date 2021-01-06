require('ae2Class')
local event = require('event')
local coroutine = require('coroutine')
local filesystem = require('filesystem')
local thread = require('thread')

function main()

    local ae2Manager=Manager.new('/home/test/ae2.cfg',50,10,-2,128)
    ae2Manager.ae2Run(true)


    -- Start some background tasks
    local background = {}
    table.insert(background, event.listen("key_up", function (key, address, char)
        if char == string.byte('q') then
            event.push('exit')
        end
    end))
    --table.insert(background, event.listen("redraw", function (key) app:draw() end))
    table.insert(background, event.listen("save", saveRecipes))
    table.insert(background, event.timer(craftingCheckInterval, checkCrafting), math.huge)
    table.insert(background, thread.create(ae2Loop))
    table.insert(background, thread.create(function() app:start() end))

    -- Block until we receive the exit signal
    local _, err = event.pull("exit")

    for _, b in ipairs(background) do
        if type(b) == 'table' and b.kill then
            b:kill()
        else
            event.cancel(b)
        end
    end

    if err then
        io.stderr:write(err)
        os.exit(1)
    else
        os.exit(0)
    end
end
main()