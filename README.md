# Landscape

Act your mobile phones as landscape. A Flutter application that turns your mobile device into a landscape display with remote control capabilities.

## Features

- **Multi-format Display**: Play GIF animations and scroll text
- **Remote Control**: Control your device remotely via HTTP API
- **Network Discovery**: Automatically scan for and connect to other devices
- **Real-time Configuration**: Update display settings remotely
- **Persistent Settings**: Configuration saved locally and synchronized across sessions

## Installation

1. Clone the repository:
```bash
git clone https://github.com/kuromesi/landscape-mobile.git
cd landscape-mobile
```

2. Install dependencies:
```bash
flutter pub get
```

3. Build and run:
```bash
flutter run
```

## Usage

### Display Modes

The app supports multiple display modes accessible through the drawer menu:

1. **GIF Player**: Play GIF animations with customizable frame rates
2. **Scroll Text**: Display scrolling text with adjustable speed, size, and direction
3. **Remote Server**: Host an HTTP server for remote control
4. **Remote Client**: Discover and connect to other devices

### GIF Player

- Tap "Load Files" to select GIF files from your device
- Use the frame rate slider to adjust animation speed
- Tap on any GIF to view it in full screen
- Swipe through the gallery to preview different GIFs
- Use the play button to view GIFs in full screen with looping

### Scroll Text

- Create and manage multiple text templates
- Customize font size, scroll speed, and direction (LTR/RTL)
- Set custom text colors using the color picker
- Templates are saved automatically and persist between sessions

### Remote Control

The app provides HTTP APIs for remote control:

#### Server Setup
1. Navigate to the "Remote Server" page
2. Start the HTTP server using the play button
3. Note the IP address and port displayed in the app bar

#### Client Connection
1. Go to the "Remote Client" page
2. Use the "Scan Network" button to find other devices
3. Select a device to pair with
4. Toggle the remote control status using the "REMOTE ON/OFF" button in the app bar

## HTTP API Endpoints

When the HTTP server is running, the following endpoints are available:

### Health Check
```
GET /livez
```
Returns: `{"isAlive": true}`

### Configuration APIs

#### Update App State
```
POST /configure/app/full
```
Update the entire app state including current page, theme, and screen settings.

#### Update Scroll Text Configuration
```
POST /configure/scroll-text/full
```
Update the scroll text configuration.

#### Update GIF Configuration
```
POST /configure/gif-player/full
```
Update the GIF player configuration.

#### Update Remote App State
```
POST /configure/remote-app
```
Update the remote app state.

#### Update Display Mode
```
GET /configure/mode?mode={mode}
```
Update the display mode (e.g., `/configure/mode?mode=/gif`).

#### Get Configuration Dump
```
GET /configure/config-dump
```
Returns the current configuration of all components.

#### Scroll Text Configuration (Legacy)
```
POST /configure/scroll-text
```
Update scroll text configuration with properties:
- `text` (String): The text content to be displayed
- `direction` (String, optional): Scroll direction ("ltr", "rtl")
- `fontSize` (double, optional): Font size
- `scrollSpeed` (double, optional): Scroll speed
- `fontColor` (int, optional): Text color in ARGB format
- `adaptiveColor` (bool, optional): Adaptive color for dark/light mode

Example:
```shell
curl 192.168.1.8:8080/configure/scroll-text -X POST -H "Content-Type: application/json" -d '{"text":"Hello this is kuromesi speaking!", "fontSize":100}'
```

## Configuration Persistence

Settings are automatically saved to device storage and persist between app sessions. However, when remote control is active, local changes are temporarily disabled to prevent conflicts.

## Development

### Project Structure
- `lib/`: Main application source code
- `lib/pages/`: UI pages for different display modes
- `lib/remote/`: Remote control and networking functionality
- `lib/apis/`: API definitions and models
- `lib/notifiers/`: State management using Provider

### Building for Release

To build a release APK:
```bash
flutter build apk --release
```

For iOS:
```bash
flutter build ios --release
```

## Troubleshooting

1. **Device Not Discoverable**: Ensure both devices are on the same WiFi network
2. **Connection Issues**: Check that the server port is not blocked by firewall
3. **API Not Responding**: Verify the server is running and the correct IP/port is used
4. **Performance Issues**: Reduce GIF frame rate or text complexity for smoother performance

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.