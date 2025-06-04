-- background.lua
-- by @wim66
-- April 17 2025
require 'cairo'
local status, cairo_xlib = pcall(require, 'cairo_xlib')

if not status then
    cairo_xlib = setmetatable({}, {
        __index = function(_, k)
            return _G[k]
        end
    })
end

local script_path = debug.getinfo(1, 'S').source:match[[^@?(.*[\/])[^\/]-$]]
local parent_path = script_path:match("^(.*[\\/])resources[\\/].*$") or ""
package.path = package.path .. ";" .. parent_path .. "?.lua"

require("settings")
conky_vars()

local unpack = table.unpack or unpack

local function parse_border_color(border_color_str)
    local gradient = {}
    for position, color, alpha in border_color_str:gmatch("([%d%.]+),0x(%x+),([%d%.]+)") do
        table.insert(gradient, {tonumber(position), tonumber(color, 16), tonumber(alpha)})
    end
    if #gradient == 3 then
        return gradient
    end
    return { {0, 0x003E00, 1}, {0.5, 0x03F404, 1}, {1, 0x003E00, 1} }
end

local function parse_bg_color(bg_color_str)
    local hex, alpha = bg_color_str:match("0x(%x+),([%d%.]+)")
    if hex and alpha then
        return { {1, tonumber(hex, 16), tonumber(alpha)} }
    end
    return { {1, 0x000000, 1} }
end

local border_color = parse_border_color(border_COLOR)
local bg_color = parse_bg_color(bg_COLOR)

local boxes_settings = {
    -- background no gradient
    {
    type = "triangle_layer",
    points = {{22, 12}, {314, 12}, {314, 294}},
    centre_x = false,
    rotation = 0,
    draw_me = true,
    colours = bg_color,
    linear_gradient = {18, 16, 310, 290},
    fill = true
    },
    -- background with gradient
    {
    type = "triangle_layer",
    points = {{22, 12}, {314, 12}, {314, 294}},
    centre_x = false,
    rotation = 0,
    draw_me = true,
    colours = {{0, 0xff0000, 0.5},{0.5, 0x00ff00, 0.5},{1, 0x0000ff, 0.5}},
    linear_gradient = {18, 16, 310, 290},
    fill = true
    },
    {
    type = "triangle_border",
    points = {{22, 12}, {314, 12}, {314, 294}},
    centre_x = false,
    rotation = 0,
    draw_me = true,
    colour = border_color,
    linear_gradient = {22, 12, 314, 294},
    border = 8,
    fill = false
    },
    -- background no gradient
    {
    type = "triangle_layer",
    points = {{6, 18}, {298, 300}, {6, 300}},
    centre_x = false,
    rotation = 0,
    draw_me = true,
    colours = bg_color,
    linear_gradient = {18, 16, 310, 290},
    fill = true
    },
    -- background with gradient
    {
    type = "triangle_layer",
    points = {{6, 18}, {298, 300}, {6, 300}},
    centre_x = false,
    rotation = 0,
    draw_me = true,
    colours = {{0, 0xff0000, 0.5},{0.5, 0x00ff00, 0.5},{1, 0x0000ff, 0.5}},
    linear_gradient = {18, 16, 310, 290},
    fill = true
    },
    {
    type = "triangle_border",
    points = {{6, 18}, {298, 300}, {6, 300}},
    centre_x = false,
    rotation = 0,
    draw_me = true,
    colour = border_color,
    linear_gradient = {22, 12, 314, 294},
    border = 8,
    fill = false
}
}

local function hex_to_rgba(hex, alpha)
    return ((hex >> 16) & 0xFF) / 255, ((hex >> 8) & 0xFF) / 255, (hex & 0xFF) / 255, alpha
end

local function draw_custom_rounded_rectangle(cr, x, y, w, h, r)
    local tl, tr, br, bl = unpack(r)
    cairo_new_path(cr)
    cairo_move_to(cr, x + tl, y)
    cairo_line_to(cr, x + w - tr, y)
    if tr > 0 then cairo_arc(cr, x + w - tr, y + tr, tr, -math.pi/2, 0) else cairo_line_to(cr, x + w, y) end
    cairo_line_to(cr, x + w, y + h - br)
    if br > 0 then cairo_arc(cr, x + w - br, y + h - br, br, 0, math.pi/2) else cairo_line_to(cr, x + w, y + h) end
    cairo_line_to(cr, x + bl, y + h)
    if bl > 0 then cairo_arc(cr, x + bl, y + h - bl, bl, math.pi/2, math.pi) else cairo_line_to(cr, x, y + h) end
    cairo_line_to(cr, x, y + tl)
    if tl > 0 then cairo_arc(cr, x + tl, y + tl, tl, math.pi, 3*math.pi/2) else cairo_line_to(cr, x, y) end
    cairo_close_path(cr)
end

local function draw_triangle(cr, x1, y1, x2, y2, x3, y3)
    cairo_new_path(cr)
    cairo_move_to(cr, x1, y1)
    cairo_line_to(cr, x2, y2)
    cairo_line_to(cr, x3, y3)
    cairo_close_path(cr)
end

local function get_centered_x(canvas_width, box_width)
    return (canvas_width - box_width) / 2
end

function conky_draw_background()
    if conky_window == nil then
        return
    end

    local cs = cairo_xlib_surface_create(conky_window.display, conky_window.drawable, conky_window.visual, conky_window.width, conky_window.height)
    local cr = cairo_create(cs)
    local canvas_width = conky_window.width

    for _, box in ipairs(boxes_settings) do
        if box.draw_me then
            local x, y, w, h = box.x, box.y, box.w, box.h
            if box.centre_x then x = get_centered_x(canvas_width, w) end

            if box.type == "background" then
                local cx, cy = x + w / 2, y + h / 2
                local angle = (box.rotation or 0) * math.pi / 180

                cairo_save(cr)
                cairo_translate(cr, cx, cy)
                cairo_rotate(cr, angle)
                cairo_translate(cr, -cx, -cy)

                cairo_set_source_rgba(cr, hex_to_rgba(box.colour[1][2], box.colour[1][3]))
                draw_custom_rounded_rectangle(cr, x, y, w, h, box.corners)
                cairo_fill(cr)

                cairo_restore(cr)

            elseif box.type == "layer2" then
                local grad = cairo_pattern_create_linear(unpack(box.linear_gradient))
                for _, color in ipairs(box.colours) do
                    cairo_pattern_add_color_stop_rgba(grad, color[1], hex_to_rgba(color[2], color[3]))
                end
                cairo_set_source(cr, grad)

                local cx, cy = x + w / 2, y + h / 2
                local angle = (box.rotation or 0) * math.pi / 180

                cairo_save(cr)
                cairo_translate(cr, cx, cy)
                cairo_rotate(cr, angle)
                cairo_translate(cr, -cx, -cy)

                draw_custom_rounded_rectangle(cr, x, y, w, h, box.corners)
                cairo_fill(cr)

                cairo_restore(cr)
                cairo_pattern_destroy(grad)

            elseif box.type == "border" then
                local grad = cairo_pattern_create_linear(unpack(box.linear_gradient))
                for _, color in ipairs(box.colour) do
                    cairo_pattern_add_color_stop_rgba(grad, color[1], hex_to_rgba(color[2], color[3]))
                end
                cairo_set_source(cr, grad)

                local cx, cy = x + w / 2, y + h / 2
                local angle = (box.rotation or 0) * math.pi / 180

                cairo_save(cr)
                cairo_translate(cr, cx, cy)
                cairo_rotate(cr, angle)
                cairo_translate(cr, -cx, -cy)

                cairo_set_line_width(cr, box.border)
                draw_custom_rounded_rectangle(
                    cr,
                    x + box.border / 2,
                    y + box.border / 2,
                    w - box.border,
                    h - box.border,
                    {
                        math.max(0, box.corners[1] - box.border / 2),
                        math.max(0, box.corners[2] - box.border / 2),
                        math.max(0, box.corners[3] - box.border / 2),
                        math.max(0, box.corners[4] - box.border / 2)
                    }
                )
                cairo_stroke(cr)

                cairo_restore(cr)
                cairo_pattern_destroy(grad)

            elseif box.type == "triangle_layer" then
                local x1, y1 = box.points[1][1], box.points[1][2]
                local x2, y2 = box.points[2][1], box.points[2][2]
                local x3, y3 = box.points[3][1], box.points[3][2]

                local cx = (x1 + x2 + x3) / 3
                local cy = (y1 + y2 + y3) / 3
                local angle = (box.rotation or 0) * math.pi / 180

                cairo_save(cr)
                cairo_translate(cr, cx, cy)
                cairo_rotate(cr, angle)
                cairo_translate(cr, -cx, -cy)

                local grad = cairo_pattern_create_linear(unpack(box.linear_gradient))
                for _, color in ipairs(box.colours) do
                    cairo_pattern_add_color_stop_rgba(grad, color[1], hex_to_rgba(color[2], color[3]))
                end
                cairo_set_source(cr, grad)

                draw_triangle(cr, x1, y1, x2, y2, x3, y3)

                if box.fill then
                    cairo_fill_preserve(cr)
                end

                cairo_restore(cr)
                cairo_pattern_destroy(grad)

            elseif box.type == "triangle_border" then
                local x1, y1 = box.points[1][1], box.points[1][2]
                local x2, y2 = box.points[2][1], box.points[2][2]
                local x3, y3 = box.points[3][1], box.points[3][2]

                local cx = (x1 + x2 + x3) / 3
                local cy = (y1 + y2 + y3) / 3
                local angle = (box.rotation or 0) * math.pi / 180

                cairo_save(cr)
                cairo_translate(cr, cx, cy)
                cairo_rotate(cr, angle)
                cairo_translate(cr, -cx, -cy)

                local grad = cairo_pattern_create_linear(unpack(box.linear_gradient))
                for _, color in ipairs(box.colour) do
                    cairo_pattern_add_color_stop_rgba(grad, color[1], hex_to_rgba(color[2], color[3]))
                end
                cairo_set_source(cr, grad)

                draw_triangle(cr, x1, y1, x2, y2, x3, y3)

                if box.border > 0 then
                    cairo_set_line_width(cr, box.border)
                    cairo_stroke(cr)
                else
                    cairo_stroke(cr)
                end

                cairo_restore(cr)
                cairo_pattern_destroy(grad)
            end
        end
    end

    cairo_destroy(cr)
    cairo_surface_destroy(cs)
end