local GUI = require('GUI')

function buildGui()
    local application = GUI.application()
    application:addChild(GUI.container(1, 1, application.width, application.height, 0x002440))
    application:addChild(GUI.panel(10, 10, application.width - 20, application.height - 20, 0x880000))
end

application:draw(true)
application:start()