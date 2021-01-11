local GUI = require('GUI')

function buildGui()
    local app = GUI.application()
    local statusBar = app:addChild(GUI.container(1, 1, 100, 50))
end

--[[function buildGui()
    local app = GUI.application()
    local statusBar = app:addChild(GUI.container(1, 1, app.width, 1))
    local window = app:addChild(GUI.container(1, 1 + statusBar.height, app.width, app.height - statusBar.height))

    window:addChild(GUI.panel(1, 1, window.width, window.height, C_BACKGROUND))
    local columns = math.floor(window.width / 60) + 1

    -- Crating queue view
    local craftingQueueView = window:addChild(GUI.layout(1, 1, window.width-1, window.height, columns, 1))
    for i = 1, columns do
        craftingQueueView:setAlignment(i, 1, GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)
        craftingQueueView:setMargin(i, 1, .5, 1)
    end

    override(craftingQueueView, 'draw', function(super, self, ...)
        self.children = {}

        local added = 0
        for _, recipe in ipairs(recipes) do
            local color =
            recipe.error and C_BADGE_ERR or
                    recipe.crafting and C_BADGE_BUSY or
                    (recipe.stored or 0) < recipe.wanted and C_BADGE

            if color then
                local badge = GUI.container(1, 1, math.floor(self.width / columns - 1), 4)
                self:setPosition(1 + added % columns, 1, self:addChild(badge))
                badge:addChild(GUI.panel(1, 1, badge.width, 4, color))
                badge:addChild(GUI.text(2, 2, C_BADGE_TEXT, recipe.label)) -- TODO: include the item icon ?
                badge:addChild(GUI.text(2, 3, C_BADGE_TEXT, string.format('%s / %s', recipe.stored or '?', recipe.wanted)))
                if recipe.error then
                    badge:addChild(GUI.text(2, 4, C_BADGE_TEXT, tostring(recipe.error)))
                    badge:moveToFront()
                end

                added = added + 1
            end
        end

        super(self, ...)
    end)

    -- Configuration view
    local SYMBOL_CONFIG_RECIPE = {}
    local configView = window:addChild(GUI.container(1, 1, window.width, window.height))
    configView:addChild(GUI.panel(1, 1, configView.width, configView.height, C_BACKGROUND))
    configView.hidden = true

    -- left panel (item select)
    local itemListSearch = configView:addChild(GUI.input(2, 2, configView.width/2-1, 3,
            C_INPUT, C_INPUT_TEXT, C_INPUT_TEXT, C_STATUS_PRESSED, C_INPUT_TEXT, '', 'Поиск'))

    -- TODO: add unconfigured/hidden filter

    local itemListPanel = configView:addChild(GUI.list(
            itemListSearch.x, itemListSearch.y + itemListSearch.height + 1, itemListSearch.width, configView.height-itemListSearch.height-3,
            1, 0, C_BADGE, C_BADGE_TEXT, C_STATUS_BAR, C_STATUS_TEXT, C_BADGE_SELECTED, C_BADGE_TEXT
    ))
    itemListPanel.selectedItem = -1
    --itemListPanel:setAlignment(GUI.ALIGNMENT_HORIZONTAL_LEFT, GUI.ALIGNMENT_VERTICAL_TOP)
    attachScrollbar(itemListPanel)

    override(itemListPanel, 'draw', function (super, self, ...)
        self.selectedItem = -1
        self.children = {}

        local selection = recipes
        local filter = itemListSearch.text
        if filter and filter ~= '' then
            filter = unicode.lower(filter)
            selection = {}
            for _, recipe in ipairs(recipes) do
                -- Patterns seem very limited, no case-insensitive option
                if unicode.lower(recipe.label):find(filter) then
                    table.insert(selection, recipe)
                end
            end
        end

        self.scrollBar.maximumValue = math.max(0, #selection - self.height)
        self.scrollBar.shownValueCount =  self.scrollBar.maximumValue / (self.scrollBar.maximumValue + 1)

        local offset = self.scrollBar.value
        for i = 1, math.min(self.height, #selection) do
            local recipe = selection[offset + i]
            local choice = self:addItem(recipe.label)
            --choice.colors.default.background = (recipe.error ~= nil) and C_BADGE_ERR or recipe.wanted > 0 and C_BADGE_BUSY or C_BADGE
            if recipe == configView[SYMBOL_CONFIG_RECIPE] then
                self.selectedItem = i
            end
            choice.onTouch = function(app, object)
                configView[SYMBOL_CONFIG_RECIPE] = recipe
                event.push('config_recipe_change')
            end
        end

        super(self, ...)
    end)

    -- right panel (item details)
    local reloadBtn = configView:addChild(GUI.button(configView.width/2+2, 2, configView.width/2-2, 3,
                                                     C_BADGE, C_BADGE_TEXT, C_BADGE, C_STATUS_PRESSED, "Перезагрузка рецептов"))
    reloadBtn.onTouch = function(app, self)
        event.push('ae2_loop', 'reload_recipes')
    end
    local itemConfigPanel = configView:addChild(GUI.layout(reloadBtn.x, reloadBtn.y + reloadBtn.height + 1, reloadBtn.width, configView.height-reloadBtn.height-7, 1, 1))
    configView:addChild(GUI.panel(itemConfigPanel.x, itemConfigPanel.y, itemConfigPanel.width, itemConfigPanel.height, C_BADGE)):moveBackward()
    itemConfigPanel:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)
    itemConfigPanel:setMargin(1, 1, .5, 1)

    override(itemConfigPanel, 'eventHandler', function(super, app, self, key, ...)
        if key == "config_recipe_change" then
            local recipe = configView[SYMBOL_CONFIG_RECIPE]

            self.children = {}
            self:addChild(GUI.text(1, 1, C_BADGE_TEXT, '[ '..recipe.label..' ]'))
            self:addChild(GUI.text(1, 1, C_BADGE_TEXT, "Хранится: "..tostring(recipe.stored)))
            self:addChild(GUI.text(1, 1, C_BADGE_TEXT, "Поддерживать"))
            local wantedInput = self:addChild(GUI.input(1, 1, 10, 3,
                    C_INPUT, C_INPUT_TEXT, 0, C_STATUS_PRESSED, C_INPUT_TEXT, tostring(recipe.wanted)))
            wantedInput.validator = numberValidator
            wantedInput.onInputFinished = function(app, object)
                recipe.wanted = tonumber(object.text) or error('cannot parse '..object.text)
                event.push('ae2_loop')
                event.push('save')
            end

            -- TODO: add remove/hide option

            -- self:draw()
            event.push('redraw') -- There is probably a more elegant way to do it ¯\_(ツ)_/¯
        end
        super(app, self, key, ...)
    end)

    local resetRecipeBtn = configView:addChild(GUI.button(itemConfigPanel.x, itemConfigPanel.y + itemConfigPanel.height + 1, itemConfigPanel.width, 3,
                                                          C_BADGE, C_BADGE_TEXT, C_BADGE, C_STATUS_PRESSED, "Не нажимать, будет cum. Русифицировано ananaslox ОнЖе AnalAnus"))
    resetRecipeBtn.onTouch = function(app, self)
        local recipe = configView[SYMBOL_CONFIG_RECIPE]
        if not recipe then return end
        for i, candidate in ipairs(recipes) do
            if (candidate == recipe) then
                table.remove(recipes, i)
                return
            end
        end
    end

    -- Staztus bar
    statusBar:addChild(GUI.panel(1, 1, statusBar.width, statusBar.height, C_STATUS_BAR))
    local statusText = statusBar:addChild(GUI.text(2, 1, C_STATUS_TEXT, ''))
    statusText.eventHandler = function(app, self)
        self.text = string.format('%d процессоров свободно из %d.  %d ошибок, %d текущее, %d запланировано.  Задержка: %.0f ms.',
            status.cpu.free, status.cpu.all, status.recipes.error, status.recipes.crafting, status.recipes.queue, status.update.duration * 1000)
    end
    statusText.eventHandler(app, statusText)
    local cfgBtn = statusBar:addChild(GUI.button(statusBar.width - 16, 1, 8, 1, C_STATUS_BAR, C_STATUS_TEXT, C_STATUS_BAR, C_STATUS_PRESSED, '[Настройки]'))
    cfgBtn.switchMode = true
    cfgBtn.animationDuration = .1
    cfgBtn.onTouch = function(app, object)
        configView.hidden = not object.pressed
    end
    statusBar:addChild(GUI.button(statusBar.width - 6, 1, 8, 1, C_STATUS_BAR, C_STATUS_TEXT, C_STATUS_BAR, C_STATUS_PRESSED, '[Выход]')).onTouch = function(app, object)
        event.push('exit')
    end
	statusBar:addChild(GUI.button(statusBar.width - 30, 1, 8, 1, C_STATUS_BAR, C_STATUS_TEXT, C_STATUS_BAR, C_STATUS_PRESSED, '[Перезагрузка]')).onTouch = function(app, object)
        computer.shutdown(true)
    end
	
    return app
end]]

--[[function attachScrollbar(obj)
    local width = (obj.width > 60) and 2 or 1
    obj.width = obj.width - width
    local bar = GUI.scrollBar(obj.x+obj.width, obj.y, width, obj.height, C_SCROLLBAR_BACKGROUND, C_SCROLLBAR,
            0, 1, 0, 1, 4, false)
    obj.parent:addChild(bar)
    obj.scrollBar = bar

    override(obj, 'eventHandler', function (super, app, self, key, ...)
        if key == 'scroll' then -- forward scrolls on the main object to the scrollbar
            bar.eventHandler(app, bar, key, ...)
        end
        super(app, self, key, ...)
    end)

    return bar
end]]

application:draw(true)
application:start()