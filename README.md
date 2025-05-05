# Conky Weather Shapes

**Conky Weather Shapes** is a customizable and visually appealing weather widget for the Conky system monitor. This repository contains configuration scripts and settings to display weather details with unique geometric shapes, such as octagons and pentagons, using Lua scripting.

## Features

- **Customizable Weather Icons**: Multiple weather icon sets with dark and light themes.
- **Geometric Shapes**: Stylish octagon and pentagon widgets to display weather information.
- **Localization Support**: Multi-language weather descriptions and labels.
- **Temperature Units**: Supports both Celsius and Fahrenheit.
- **Gradient Colors**: Configurable gradients for borders and backgrounds.
- **OpenWeatherMap API Integration**: Fetch live weather data using your API key.

## Getting Started

### Prerequisites

- **Conky**: Ensure you have Conky installed. [Conky Documentation](https://github.com/brndnmtthws/conky)
- **Lua**: Lua interpreter for executing scripts.

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/wim66/Conky-Weather-Shapes.git
   ```
2. Navigate to the project directory:
   ```bash
   cd Conky-Weather-Shapes
   ```
3. Choose a configuration: octagon or pentagon. Each has its own `settings.lua` file.

### Configuration

1. Obtain a free API key from [OpenWeatherMap](https://openweathermap.org/).
2. Update the `API_KEY` in the appropriate `settings.lua` file:
   ```lua
   API_KEY = "your_api_key_here"
   ```
3. Set your `CITY_ID`:
   - Visit [OpenWeatherMap](https://openweathermap.org/).
   - Search for your city and copy the ID from the URL.
   ```lua
   CITY_ID = "your_city_id_here"
   ```
4. Optional: Customize other settings such as `ICON_SET`, `UNITS`, `LANG`, `border_COLOR`, and `bg_COLOR`.

### Running the Widget

1. Start Conky with the desired configuration:
   ```bash
   start.sh
   ```

## Customization Options

- **Weather Icons**: Choose from a variety of dark and light themes.
- **Gradient Borders**: Define custom gradients for widget borders.
- **Languages**: Supported languages include English (`en`), Dutch (`nl`), French (`fr`), Spanish (`es`), and German (`de`).
- **Units**: Display temperature in Celsius or Fahrenheit.

## File Structure

- `octagon-conky/settings.lua`: Configuration for the octagon-shaped widget.
- `pentagon-conky/settings.lua`: Configuration for the pentagon-shaped widget.

## Contributing

Contributions are welcome! If you have ideas for new shapes, themes, or features, feel free to fork the repository and submit a pull request.

## License

This project does not currently specify a license. Contact the repository owner for usage permissions.

## Author

- Developed by [wim66](https://github.com/wim66).

---

*This project is a work in progress. Additional features and improvements are planned. Stay tuned!*