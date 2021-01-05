local component = require('component')
local computer = require('computer')
local coroutine = require('coroutine')
local event = require('event')
local filesystem = require('filesystem')
local serialization = require('serialization')
local thread = require('thread')
local unicode = require('unicode')





print("Поиск МЭ интерфейса...")
local ae2=component['me_interface']
print("Используется интерфейс с адресом "..ae2['id'])

print('Загрузка конфигурации из '..configPath)
local f, err = io.open(configPath, 'r')

function loadRecipes()
    
    
    if not f then
        -- usually the file does not exist, on the first run
        print('Loading failed:', err)
        return
    end

    local content = serialization.unserialize(f:read('a'))

    f:close()

    recipes = content.recipes
    print('Loaded '..#recipes..' recipes')
end



