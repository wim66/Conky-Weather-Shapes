-- pentagon.lua
-- by @wim66
-- May 5 2025

-- Load Cairo library and handle Xlib surface creation
require 'cairo'
local status, cairo_xlib = pcall(require, 'cairo_xlib')

if not status then
    -- Fallback for missing cairo_xlib, mapping to global functions
    cairo_xlib = setmetatable({}, {
        __index = function(_, k)
            return _G[k]
        end
    })
end

-- Set up script path to include parent directory for module loading
local script_path = debug.getinfo(1, 'S').source:match[[^@?(.*[\/])[^\/]-$]]
local parent_path = script_path:match("^(.*[\\/])resources[\\/].*$") or ""
package.path = package.path .. ";" .. parent_path .. "?.lua"

-- Load settings and Conky variables
require("settings")
conky_vars()

-- Parse gradient color string (position, hex, alpha) with default fallback
local function parse_color(color_str, default)
    local gradient = {}
    for position, color, alpha in color_str:gmatch("([%d%.]+),0x(%x+),([%d%.]+)") do
        table.insert(gradient, {tonumber(position), tonumber(color, 16), tonumber(alpha)})
    end
    return #gradient == 3 and gradient or default
end

-- Parse background color string (hex, alpha) with default fallback
local function parse_bg_color(bg_color_str)
    local hex, alpha = bg_color_str:match("0x(%x+),([%d%.]+)")
    if hex and alpha then
        return { {1, tonumber(hex, 16), tonumber(alpha)} }
    end
    return { {1, 0x000000, 1} }
end

-- Initialize color settings with parsed values or defaults
local border_color = parse_color(border_COLOR, { {0, 0x003E00, 1}, {0.5, 0x03F404, 1}, {1, 0x003E00, 1} })
local bg_color = parse_bg_color(bg_COLOR)

-- Define pentagon layers and border settings
local function get_boxes_settings()
    return {
        {
            type = "pentagon_layer",
            x = 256,
            y = 240,
            radius = 210,
            center = true, -- Center on canvas, ignores x and y
            rotation = 0,
            draw_me = true,
            colours = bg_color, -- Use bg_color from settings.lua
            linear_gradient = {0, 70, 0, 450}, -- Manual gradient (use nil for dynamic)
            fill = true
        },
        {
            type = "pentagon_layer",
            x = 256,
            y = 240,
            radius = 210,
            center = true, -- Center on canvas, ignores x and y
            rotation = 0,
            draw_me = true,
            colours = {{0, 0xFFFFFF, 0.05}, {0.5, 0xC2C2C2, 0.33}, {1, 0xFFFFFF, 0.05}}, -- Original colors
            linear_gradient = {0, 70, 0, 450}, -- Manual gradient (use nil for dynamic)
            fill = true
        },
        {
            type = "pentagon_border",
            x = 256,
            y = 240,
            radius = 210,
            center = true, -- Center on canvas, ignores x and y
            rotation = 0,
            draw_me = true,
            colour = border_color, -- Use border_color2 for consistency with octagon.lua
            linear_gradient = {0, 0, 0, 500}, -- Manual gradient (use nil for dynamic)
            border = 8,
            fill = false
        },
    }
end

-- Compatibility for table.unpack
local unpack = table.unpack or unpack

-- Constant for number of pentagon sides
local PENTAGON_SIDES = 5

-- Convert hex color to RGBA format
local function hex_to_rgba(hex, alpha)
    return ((hex >> 16) & 0xFF) / 255, ((hex >> 8) & 0xFF) / 255, (hex & 0xFF) / 255, alpha
end

-- Generate points for a pentagon based on center and radius
local function generate_pentagon_points(center_x, center_y, radius)
    local points = {}
    local angle_step = 2 * math.pi / PENTAGON_SIDES
    for i = 0, PENTAGON_SIDES - 1 do
        local angle = i * angle_step - math.pi / 2
        local x = center_x + radius * math.cos(angle)
        local y = center_y + radius * math.sin(angle)
        table.insert(points, {x, y})
    end
    return points
end

-- Draw a pentagon using the provided points
local function draw_pentagon(cr, points)
    cairo_new_path(cr)
    for i, point in ipairs(points) do
        local x, y = point[1], point[2]
        if i == 1 then
            cairo_move_to(cr, x, y)
        else
            cairo_line_to(cr, x, y)
        end
    end
    cairo_close_path(cr)
end

-- Main function to draw pentagons on Conky canvas
function conky_draw_pentagon()
    if conky_window == nil then
        return
    end

    -- Create Cairo surface and context
    local cs = cairo_xlib_surface_create(conky_window.display, conky_window.drawable, conky_window.visual, conky_window.width, conky_window.height)
    local cr = cairo_create(cs)

    -- Get boxes settings
    local boxes = get_boxes_settings()

    -- Process each box in settings
    for _, box in ipairs(boxes) do
        if box.draw_me then
            -- Determine center point
            local center_x, center_y
            if box.center then
                center_x = conky_window.width / 2
                center_y = conky_window.height / 2
            else
                if not box.x or not box.y then
                    print("Error: Missing x or y for box " .. _ .. " when center is false")
                    return
                end
                center_x = box.x
                center_y = box.y
            end

            -- Validate radius
            if not box.radius then
                print("Error: Missing radius for box " .. _)
                return
            end

            -- Generate pentagon points
            local pentagon_points = generate_pentagon_points(center_x, center_y, box.radius)

            -- Set gradient, use dynamic if manual is invalid or nil
            local gradient = box.linear_gradient
            if not gradient or type(gradient) ~= "table" or #gradient ~= 4 then
                gradient = {center_x - box.radius, center_y, center_x + box.radius, center_y}
            end

            if box.type == "pentagon_layer" then
                -- Validate points and colors
                if not pentagon_points or type(pentagon_points) ~= "table" or #pentagon_points < PENTAGON_SIDES then
                    print("Error: pentagon_points is not a valid table for box " .. _)
                    return
                end
                if not box.colours or type(box.colours) ~= "table" or #box.colours == 0 then
                    print("Error: Invalid colours for box " .. _ .. ": ", box.colours)
                    return
                end

                -- Apply rotation and draw layer
                local angle = (box.rotation or 0) * math.pi / 180
                cairo_save(cr)
                cairo_translate(cr, center_x, center_y)
                cairo_rotate(cr, angle)
                cairo_translate(cr, -center_x, -center_y)

                local grad = cairo_pattern_create_linear(unpack(gradient))
                for _, color in ipairs(box.colours) do
                    cairo_pattern_add_color_stop_rgba(grad, color[1], hex_to_rgba(color[2], color[3]))
                end
                cairo_set_source(cr, grad)

                draw_pentagon(cr, pentagon_points)

                if box.fill then
                    cairo_fill_preserve(cr)
                end

                cairo_restore(cr)
                cairo_pattern_destroy(grad)

            elseif box.type == "pentagon_border" then
                -- Validate points and color
                if not pentagon_points or type(pentagon_points) ~= "table" or #pentagon_points < PENTAGON_SIDES then
                    print("Error: pentagon_points is not a valid table for box " .. _)
                    return
                end
                if not box.colour or type(box.colour) ~= "table" or #box.colour == 0 then
                    print("Error: Invalid colour for box " .. _ .. ": ", box.colour)
                    return
                end

                -- Apply rotation and draw border
                local angle = (box.rotation or 0) * math.pi / 180
                cairo_save(cr)
                cairo_translate(cr, center_x, center_y)
                cairo_rotate(cr, angle)
                cairo_translate(cr, -center_x, -center_y)

                local grad = cairo_pattern_create_linear(unpack(gradient))
                for _, color in ipairs(box.colour) do
                    cairo_pattern_add_color_stop_rgba(grad, color[1], hex_to_rgba(color[2], color[3]))
                end
                cairo_set_source(cr, grad)

                draw_pentagon(cr, pentagon_points)

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

    -- Clean up Cairo resources
    cairo_destroy(cr)
    cairo_surface_destroy(cs)
end