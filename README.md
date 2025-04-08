Realtime ETA Clock
A SwiftUI application that provides a real-time clock with travel time estimation capabilities, designed to help users manage their travel schedules effectively.
Show Image
Features

Real-time Clock: Displays current time and date in a clean, monospaced font
Location-based ETA: Calculates estimated time of arrival to user-specified destinations
"Leave By" Planning: Calculate when you need to leave to arrive at a specific time
Travel Time Display: Shows travel duration in hours and minutes
Notifications: Optional alerts when it's time to depart
Cross-platform: Designed for both iOS and macOS
Responsive Design: Adapts to different screen sizes and orientations

Technical Implementation
Core Technologies

SwiftUI for UI components and layout
CoreLocation for user's current location
MapKit for geocoding and travel time calculation
UserNotifications for departure reminders
SwiftData for data persistence

Architecture
The app follows a clean, modular structure:

LocationManager: Handles location services and permissions
NotificationManager: Manages user notification requests and scheduling
ClockETAView: Main view containing all UI elements and business logic
Conditional compilation to handle platform-specific features (iOS/macOS)

Key Components
1. Real-time Clock
Updates every second using a Timer publisher with automatic connection to the SwiftUI view lifecycle.
2. ETA Calculation
When a user enters a destination:

The app geocodes the text to location coordinates
Calculates the expected travel time using MapKit routing
Determines arrival time based on current time and travel duration
Alternatively calculates departure time based on desired arrival time

3. UI Organization
The interface uses a TabView with three tabs:

Basic clock view with minimal ETA information
Detailed travel information view
Settings and input view for destination and notification preferences

Getting Started
Prerequisites

Xcode 15.0 or later
iOS 17.0+ / macOS 14.0+
Apple Developer Account for testing on real devices

Installation

Clone this repository
Open RealTimeClock.xcodeproj in Xcode
Select your target device
Build and run the application

Required Capabilities

Location Services
Notification Services

Usage

Launch the app to see the current time and date
Swipe to the third tab to enter a destination
Optionally toggle "Set Desired Arrival Time" to plan when you need to leave
Press "Calculate ETA" to see your travel time and estimated arrival
Enable notifications to receive an alert when it's time to leave

Future Enhancements

Multiple travel modes (walking, public transit, etc.)
Weather integration for travel planning
Saved favorite destinations
Traffic condition updates
Widget support for at-a-glance information
Apple Watch companion app

License
This project is licensed under the MIT License - see the LICENSE file for details.
Acknowledgements

Apple's SwiftUI, CoreLocation and MapKit frameworks
[List any additional libraries or resources used]

Contact
Your Name - RealCharredApps@icloud.com
Project Link: https://github.com/RealCharredApps/Realtime_ETA_Clock_Swift_IOS
