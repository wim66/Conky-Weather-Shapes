--[[
############################################################
# conky-time-lua                                           #
# Original by +WillemO @wim66                              #
# Updated: April 27, 2025                                  #
# Simplified clock with day and date, single colors, group rotation #
# Requires: background.lua + loadall.lua                   #
############################################################
]]

require 'cairo'
local status, cairo_xlib = pcall(require, 'cairo_xlib')

if not status then
    cairo_xlib = setmetatable({}, {
        __index = function(_, k)
            return _G[k]
        end
    })
end

function conky_draw_text()
    local group_angle = 45 -- Rotatiehoek voor de hele groep in graden
    local group_x = 230 -- X-coördinaat van het groepscentrum
    local group_y = 100 -- Y-coördinaat van het groepscentrum

    text_settings = {
        -- CLOCK
        {
            text = conky_parse("${time %H:%M}"),
            font_name = "zekton",
            font_size = 30,
            h_align = "c",
            v_align = "m",
            bold = true,
            x = 0, -- Relatief t.o.v. groepscentrum, wordt later aangepast
            y = -50, -- Boven de groepscentrum
            colour = {{1, 0xFFFF00, 0.85}}, -- Wit
        },
        -- DAY
        {
            text = conky_parse("${time %A}"),
            font_name = "DejaVu Sans",
            font_size = 28,
            h_align = "c",
            v_align = "m",
            bold = false,
            x = 0, -- Relatief t.o.v. groepscentrum
            y = 0, -- Midden van de groep
            colour = {{1, 0xFFFF00, 0.85}},
        },
        -- DATE
        {
            text = conky_parse("${time %d %B %Y}"),
            font_name = "DejaVu Sans",
            font_size = 28,
            h_align = "c",
            v_align = "m",
            bold = false,
            x = 0, -- Relatief t.o.v. groepscentrum
            y = 50, -- Onder de groepscentrum
            colour = {{1, 0xFFFF00, 0.85}},
        },
    }

    if conky_window == nil then return end
    if tonumber(conky_parse("$updates")) < 3 then return end

    local cs = cairo_xlib_surface_create(conky_window.display,
                                         conky_window.drawable,
                                         conky_window.visual,
                                         conky_window.width,
                                         conky_window.height)
    local cr = cairo_create(cs)

    -- Pas groepstransformatie toe (rotatie rond groepscentrum)
    cairo_translate(cr, group_x, group_y)
    cairo_rotate(cr, group_angle * math.pi / 180)
    cairo_save(cr)

    for _, t in ipairs(text_settings) do
        -- Set font
        local weight = t.bold and CAIRO_FONT_WEIGHT_BOLD or CAIRO_FONT_WEIGHT_NORMAL
        cairo_select_font_face(cr, t.font_name, CAIRO_FONT_SLANT_NORMAL, weight)
        cairo_set_font_size(cr, t.font_size)

        -- Calculate text extents
        local te = cairo_text_extents_t:create()
        cairo_text_extents(cr, t.text, te)

        -- Calculate position based on alignment
        local mx, my = 0, 0
        if t.h_align == "c" then mx = -te.width / 2 end
        if t.v_align == "m" then my = -te.height / 2 - te.y_bearing end

        -- Set single color
        local r, g, b, a = rgb_to_r_g_b2(t.colour[1])
        cairo_set_source_rgba(cr, r, g, b, a)

        -- Draw text at relative position
        cairo_move_to(cr, mx + t.x, my + t.y)
        cairo_show_text(cr, t.text)
    end

    cairo_restore(cr)
    cairo_destroy(cr)
    cairo_surface_destroy(cs)
end

function rgb_to_r_g_b2(tcolour)
    local colour, alpha = tcolour[2], tcolour[3]
    return ((colour / 0x10000) % 0x100) / 255.,
           ((colour / 0x100) % 0x100) / 255.,
           (colour % 0x100) / 255., alpha
end