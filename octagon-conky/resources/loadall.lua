-- loadall.lua
-- by @wim66
-- April 17 2025

-- Set the path to the scripts folder
package.path = "./resources/?.lua"
-- ###################################


require 'octagon'
require 'display'
require 'clock'

function conky_main()
    if conky_window == nil then
        return
    end
    conky_draw_octagon()
    conky_draw_weather()
    conky_draw_text()
end
