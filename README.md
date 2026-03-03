# StickyNote

A modern, open-source sticky notes application for macOS. StickyNote brings the classic sticky notes experience to your desktop with a beautiful, native design that blends seamlessly with macOS.

## Features

- **Floating Notes** - Notes float above other windows, always accessible when you need them
- **Pin to Top** - Pin important notes to stay visible even above fullscreen apps
- **Multiple Colors** - Choose from 6 beautiful Apple device-inspired colors (Silver, Space Gray, Gold, Rose Gold, Blue, Purple)
- **Collapse/Expand** - Double-click the header or use the collapse button to minimize notes
- **Transparent Blur** - Modern frosted glass appearance with adjustable transparency
- **Plain Text Only** - Automatically strips formatting when pasting, keeping notes clean and simple
- **Auto-Save** - Notes are automatically saved as you type
- **Menu Bar App** - Lives in your menu bar, no dock icon clutter
- **Multi-Space Support** - Notes follow you across all desktops and spaces
- **Dark Mode Support** - Looks great in both light and dark mode

## Requirements

- macOS 13.0 (Ventura) or later
- Apple Silicon or Intel Mac

## Installation

### Download from Releases

1. Go to the [Releases](../../releases) page
2. Download the latest `StickyNote.app.zip`
3. Unzip and drag `StickyNote.app` to your Applications folder
4. Launch StickyNote from Applications or Spotlight

### Build from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/sticky-notes.git
   cd sticky-notes/StickyNote
   ```

2. Open in Xcode:
   ```bash
   open StickyNote.xcodeproj
   ```

3. Build and run:
   - Select your Mac as the run destination
   - Press `Cmd + R` to build and run

   Or build from command line:
   ```bash
   xcodebuild -scheme StickyNote -configuration Release build
   ```

## Usage

1. **Create a Note** - Click the menu bar icon and select "New Note"
2. **Move a Note** - Drag the header area to reposition
3. **Resize a Note** - Drag the edges or corners
4. **Change Color** - Click the three-dot menu and select a color
5. **Collapse a Note** - Double-click the header or click the minus button
6. **Pin a Note** - Use the menu to pin notes above all other windows
7. **Close a Note** - Click the X button (notes with content will ask for confirmation)
8. **Delete a Note** - Use the three-dot menu to permanently delete

## App Store

StickyNote will be available on the Mac App Store soon. Stay tuned!

## Contributing

Contributions are welcome! Feel free to:

- Report bugs
- Suggest new features
- Submit pull requests

## License

This project is open source and available under the [MIT License](LICENSE).

## Acknowledgments

- Built with SwiftUI and AppKit
- Inspired by the classic macOS Stickies app
- Colors inspired by Apple device finishes
