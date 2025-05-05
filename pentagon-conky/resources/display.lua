-- display.lua – Conky Weather with Cycling Labels and Flip Down Effect
-- by @wim66 – April 8, 2025
-- Fixed to combine Min and Max on one line, center all text, and ensure reliable cycling

require 'cairo'
-- Try to require the 'cairo_xlib' module safely
local status, cairo_xlib = pcall(require, 'cairo_xlib')

if not status then
    -- If the module is not found, fall back to a dummy table
    -- This dummy table redirects all unknown keys to the global namespace (_G)
    -- This allows usage of global Cairo functions like cairo_xlib_surface_create
    cairo_xlib = setmetatable({}, {
        __index = function(_, k)
            return _G[k]
        end
    })
end

-- Data fetch settings
local FETCH_INTERVAL = 30 -- Seconds between running get_forecast.sh
local last_fetch_time = 0
local FORCE_FETCH = false
-- Dynamic path
local SCRIPT_DIR = debug.getinfo(1, 'S').source:match[[^@?(.*[\/])[^\/]-$]] or "./resources/"
local FETCH_SCRIPT = SCRIPT_DIR .. "get_weather.sh"

-- Global variables for label cycling and animation
local frame_count = 0               -- Counts frames for timing (based on update_interval)
local label_cycle_frames = 10       -- Number of frames between label changes (3 seconds at 10 updates/sec)
local current_label_index = 1       -- Index of the currently displayed label
local is_animating = false          -- Tracks if an animation is in progress
local animation_frame = 0           -- Current frame of the animation
local animation_duration = 3        -- Animation duration in frames (0.5 seconds at 10 updates/sec)
local previous_label_index = 1      -- Index of the previous label for animation

-- Function to load weather data from a file
local function read_weather_data()
    local weather_data = {}
    local file = io.open("./resources/cache/weather_data.txt", "r")
    if not file then return weather_data end

    -- Parse key-value pairs from the file
    for line in file:lines() do
        local key, value = line:match("([^=]+)=([^=]+)")
        if key and value then
            weather_data[key] = value
        end
    end
    file:close()
    return weather_data
end

-- Function to calculate text width for centering
local function get_text_width(cr, text, font, size)
    cairo_select_font_face(cr, font, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
    cairo_set_font_size(cr, size)
    local extents = cairo_text_extents_t:create()
    cairo_text_extents(cr, text, extents)
    return extents.width
end

-- Function to draw text with specified properties
local function draw_text(cr, text, x, y, font, size, color, alpha)
    cairo_select_font_face(cr, font, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
    cairo_set_font_size(cr, size)
    cairo_set_source_rgba(cr, color[1], color[2], color[3], alpha or color[4])
    cairo_move_to(cr, x, y)
    cairo_show_text(cr, text)
end

-- Language-based label translations and data pairs, with Min and Max combined
local function get_label_pairs(lang, weather_data)
    local labels = {}
    if lang == "nl" then
        labels = {
            {text = "Temp: " .. (weather_data.TEMP or "N/A")},
            {text = "Min: " .. (weather_data.TEMP_MIN or "N/A") .. " Max: " .. (weather_data.TEMP_MAX or "N/A")},
            {text = "Luchtvochtigheid: " .. (weather_data.HUMIDITY or "N/A") .. "%"},
            {text = "Wind snelheid: " .. (weather_data.WIND_SPEED or "N/A") .. " m/s"}
        }
    elseif lang == "en" then
        labels = {
            {text = "Temp: " .. (weather_data.TEMP or "N/A")},
            {text = "Min: " .. (weather_data.TEMP_MIN or "N/A") .. " Max: " .. (weather_data.TEMP_MAX or "N/A")},
            {text = "Humidity: " .. (weather_data.HUMIDITY or "N/A") .. "%"},
            {text = "Wind Speed: " .. (weather_data.WIND_SPEED or "N/A") .. " m/s"}
        }
    elseif lang == "fr" then
        labels = {
            {text = "Temp: " .. (weather_data.TEMP or "N/A")},
            {text = "Min: " .. (weather_data.TEMP_MIN or "N/A") .. " Max: " .. (weather_data.TEMP_MAX or "N/A")},
            {text = "Humidité: " .. (weather_data.HUMIDITY or "N/A") .. "%"},
            {text = "Vitesse du vent: " .. (weather_data.WIND_SPEED or "N/A") .. " m/s"}
        }
    elseif lang == "es" then
        labels = {
            {text = "Temp: " .. (weather_data.TEMP or "N/A")},
            {text = "Min: " .. (weather_data.TEMP_MIN or "N/A") .. " Max: " .. (weather_data.TEMP_MAX or "N/A")},
            {text = "Humedad: " .. (weather_data.HUMIDITY or "N/A") .. "%"},
            {text = "Velocidad del viento: " .. (weather_data.WIND_SPEED or "N/A") .. " m/s"}
        }
    elseif lang == "de" then
        labels = {
            {text = "Temp: " .. (weather_data.TEMP or "N/A")},
            {text = "Min: " .. (weather_data.TEMP_MIN or "N/A") .. " Max: " .. (weather_data.TEMP_MAX or "N/A")},
            {text = "Luftfeuchtigkeit: " .. (weather_data.HUMIDITY or "N/A") .. "%"},
            {text = "Windgeschwindigkeit: " .. (weather_data.WIND_SPEED or "N/A") .. " m/s"}
        }
    else
        labels = {
            {text = "Temp: " .. (weather_data.TEMP or "N/A")},
            {text = "Min: " .. (weather_data.TEMP_MIN or "N/A") .. " Max: " .. (weather_data.TEMP_MAX or "N/A")},
            {text = "Humidity: " .. (weather_data.HUMIDITY or "N/A") .. "%"},
            {text = "Wind Speed: " .. (weather_data.WIND_SPEED or "N/A") .. " m/s"}
        }
    end
    return labels
end

-- Main function to draw the weather display
function conky_draw_weather()
    if conky_window == nil then return end

    -- Run initial fetch at startup
    if last_fetch_time == 0 then
        local cmd = FETCH_SCRIPT
        if FORCE_FETCH then
            cmd = cmd .. " --force"
        end
        io.popen(cmd .. " 2>&1"):close()
    end

    -- Check if it's time to fetch new data
    local current_time = os.time()
    if current_time - last_fetch_time >= FETCH_INTERVAL then
        local cmd = FETCH_SCRIPT
        if FORCE_FETCH then
            cmd = cmd .. " --force"
        end
        local handle = io.popen(cmd .. " 2>&1")
        local output = handle:read("*all")
        handle:close()
        last_fetch_time = current_time
    end
        
    -- Load weather data
    local weather_data = read_weather_data()
    local city = weather_data.CITY or "N/A"
    local lang = weather_data.LANG or "en"
    local weather_desc = weather_data.WEATHER_DESC or "N/A"

    -- Get label-value pairs for cycling
    local label_pairs = get_label_pairs(lang, weather_data)

    -- Create Cairo surface and context
    local cs = cairo_xlib_surface_create(conky_window.display, conky_window.drawable, conky_window.visual,
                                         conky_window.width, conky_window.height)
    local cr = cairo_create(cs)

    -- Draw weather icon
    local weather_icon_path = "./resources/cache/weathericon.png"
    local image = cairo_image_surface_create_from_png(weather_icon_path)
    local img_w = cairo_image_surface_get_width(image)
    local img_h = cairo_image_surface_get_height(image)
    local image_x = (conky_window.width - 120) / 2 -- Center horizontally
    cairo_save(cr)
    cairo_translate(cr, image_x, 75)
    cairo_scale(cr, 120 / img_w, 120 / img_h)
    cairo_set_source_surface(cr, image, 0, 0)
    cairo_paint(cr)
    cairo_restore(cr)
    cairo_surface_destroy(image)

    -- Draw centered city name
    local city_font = "ChopinScript"
    local city_size = 72
    local city_color = {1, 0.4, 0, 1}
    local city_width = get_text_width(cr, city, city_font, city_size)
    local city_x = (conky_window.width - city_width) / 2 -- Center horizontally
    draw_text(cr, city, city_x, 230, city_font, city_size, city_color)

    -- Draw centered weather description (static)
    local desc_font = "Dejavu Serif"
    local desc_size = 22
    local desc_color = {1, 0.66, 0, 1}
    local desc_width = get_text_width(cr, weather_desc, desc_font, desc_size)
    local desc_x = (conky_window.width - desc_width) / 2 -- Center horizontally
    draw_text(cr, weather_desc, desc_x, 270, desc_font, desc_size, desc_color)

    -- Label cycling and animation logic
    frame_count = frame_count + 1

    -- Check if it's time to switch labels (every 3 seconds)
    if frame_count >= label_cycle_frames and not is_animating then
        previous_label_index = current_label_index
        current_label_index = current_label_index + 1
        if current_label_index > #label_pairs then
            current_label_index = 1 -- Reset to first label
        end
        is_animating = true -- Start animation
        animation_frame = 0 -- Reset animation frame
        frame_count = 0     -- Reset frame counter
    end

    -- Get current and previous label texts
    local current_text = label_pairs[current_label_index].text
    local previous_text = label_pairs[previous_label_index].text

    -- Draw labels with flip down effect, centered
    local label_font = "Dejavu Serif"
    local label_size = 22
    local label_color = {1, 0.66, 0, 1}
    local label_y_base = 300

    if is_animating then
        animation_frame = animation_frame + 1
        local progress = animation_frame / animation_duration -- Animation progress (0 to 1)

        -- Calculate positions for flip effect
        local old_y = label_y_base + (progress * 30) -- Old label moves down (30 pixels max)
        local new_y = (label_y_base - 30) + (progress * 30) -- New label moves from above to base

        -- Center old label
        local old_width = get_text_width(cr, previous_text, label_font, label_size)
        local old_x = (conky_window.width - old_width) / 2
        draw_text(cr, previous_text, old_x, old_y, label_font, label_size, label_color, 1 - progress)

        -- Center new label
        local new_width = get_text_width(cr, current_text, label_font, label_size)
        local new_x = (conky_window.width - new_width) / 2
        draw_text(cr, current_text, new_x, new_y, label_font, label_size, label_color, progress)

        -- End animation when complete
        if animation_frame >= animation_duration then
            is_animating = false
        end
    else
        -- Draw current label statically when not animating, centered
        local label_width = get_text_width(cr, current_text, label_font, label_size)
        local label_x = (conky_window.width - label_width) / 2
        draw_text(cr, current_text, label_x, label_y_base, label_font, label_size, label_color)
    end

    -- Clean up Cairo resources
    cairo_destroy(cr)
    cairo_surface_destroy(cs)
end

-- Entry point for Conky
function conky_main()
    conky_draw_weather()
end