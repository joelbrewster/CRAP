# CurrentlyRunningAppProcess

## Overview
The CurrentlyRunningAppProcess is a macOS application that displays a small, floating icon in the status bar, representing the currently active application. The icon updates dynamically to reflect the app in focus, providing a quick visual reference for users.
Do note, I'm not a Swift developer at all, so this is a simple project that I'm working on for fun and because I'm curious.

## Features
- **Dynamic Icon Update**: The app automatically updates the displayed icon based on the currently active application.
- **Floating Window**: The icon is displayed in a borderless, transparent window that hovers over other applications.
- **Adaptive Appearance**: The icon's appearance adjusts based on the system's light or dark mode, ensuring optimal visibility.
- **Grayscale Filter**: The app applies a grayscale filter to the icon, enhancing its visibility and aesthetics.

## Usage
Once the application is running, it will automatically display the icon of the currently active application in the status bar. The icon will update in real-time as you switch between applications. Closing the application is done by activity monitor.

## License
This project is licensed under the GNU General Public License (GPL). 

You can redistribute and modify this project under the terms of the GNU GPL. This means you can use, modify, and distribute the software, but any derivative work must also be licensed under the GPL.

For more details, please refer to the [GNU General Public License](https://www.gnu.org/licenses/gpl-3.0.html).