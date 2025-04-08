//
//  ContentView.swift
//  RealTimeClock
//
//  Created by BBM 2 on 10/5/24.
//

import SwiftUI
import SwiftData
import CoreLocation
import MapKit
import UserNotifications

#if canImport(UIKit)
import UIKit  // <-- Import UIKit only on iOS

// Hide keyboard function for iOS (not available on macOS)
func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}
#endif



// Location Manager to get user's current location
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var currentLocation: CLLocationCoordinate2D? = nil
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    // Update the current location when the user moves
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            DispatchQueue.main.async {
                self.currentLocation = location.coordinate
            }
            // Recalculate ETA whenever location changes
            NotificationCenter.default.post(name: .locationDidChange, object: nil)
        }
    }
}


// Notification Manager to handle user notifications
class NotificationManager {
    static let shared = NotificationManager()
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Permission granted for notifications")
            } else if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleNotification(at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Time to Leave"
        content.body = "It's time to leave now to reach your destination on time."
        content.sound = UNNotificationSound.default
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date), repeats: false)
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Notification scheduled successfully")
            }
        }
    }
}



//format the clock feature stuff
struct ClockETAView: View {
    //1st what do you need to show/do
    //show current time
    @State private var currentTime = Date()
    @State private var currentDate = Date()
    //show location stuff
    @StateObject private var locationManager = LocationManager()
    @State private var eta: Date? = nil  // ETA as Date for real-time update
    @State private var travelTimeInSeconds: TimeInterval = 0  // Store initial travel time
    @State private var timeToLeave: Date? = nil  // Calculated time to leave
    @State private var showETAOptions = false  // Toggle to show/hide ETA-related options
    @State private var useArrivalTime = false  // Toggle to use or hide "Arrive by" setting
    @State private var notificationsEnabled = false  // Toggle for notifications
    @State private var arrivalTime = Date()  // Desired arrival time (user input)
    @State private var destination: String = ""  // This stores the user input
    // tab views
    @State private var selection = 0 // State to manage the current tab
    @State private var isKeyboardVisible = false
    
    //device environment
    @Environment(\.horizontalSizeClass) var sizeClass  // Detects device orientation (portrait/landscape)
    
    @FocusState private var isTextFieldFocused: Bool  // iOS 15+ feature
    
    
    
    //2nd what do you need to happen before can see it
    //update every second with a timer
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    //date stuff
    let date = Date()
    
    
    
    
    //3rd how do you want to see it like css
    //the display stuff
    var body: some View {
        
        
        // ETA Info tab View
        
        //Tab 1
        // TabView to switch between Clock and ETA Info
        TabView(selection: $selection) {
            // First tab: Large clock
            VStack {
                //display current time
                Text(timeString(from: currentTime))
                    .font(.system(size: sizeClass == .compact ? 93 : 120, weight: .bold, design: .monospaced))
                
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color.primary)
                    .padding(50)
                
                //display the date
                Text(dateString(from: date))
                    .font(.system(size: sizeClass == .compact ? 30 : 45, weight: .bold, design: .monospaced))
                //.font(.system(size: 45, weight: .light, design: .monospaced))
                    .multilineTextAlignment(.center)
                //.foregroundColor(.teal)
                    .foregroundColor(Color.primary)
                    .padding()
                
                // Display Time to Leave and ETA
                if useArrivalTime, let timeToLeave = timeToLeave {
                    Text("Destination: \(destination) \n Leave by \(timeString(from: timeToLeave))")
                        .font(.system(size: 22, weight: .medium, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color.primary)
                        .padding()
                } else if let eta = eta {
                    Text("\(destination) ETA: \(timeString(from: eta))")
                        .font(.system(size: 22, weight: .medium, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color.primary)
                        .padding()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            .gesture(DragGesture())  // Prevent ScrollView from hijacking TabView swipe
            
            .tag(0)  // First tab (Clock)
            
            
            
            //second tab
                    
                    VStack {
                        //display current time in a format defined later
                        Text(timeString(from: currentTime))
                            .font(.system(size: sizeClass == .compact ? 93 : 120, weight: .bold, design: .monospaced))
                        
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color.primary)
                            .padding(50)
                        
                        //display the date
                        Text(dateString(from: date))
                            .font(.system(size: sizeClass == .compact ? 30 : 45, weight: .bold, design: .monospaced))
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color.primary)
                            .padding(.vertical, 10)
                        
                        // Display ETA Result
                        // Display how long to get to destination
                        if travelTimeInSeconds > 0 {
                            // Display time to destination
                            if travelTimeInSeconds < 2 {
                                Text("You're already here!")
                                    .font(.system(size: 24, weight: .medium, design: .monospaced))
                                    .foregroundColor(.teal)
                                    .padding()
                            } else {
                                Text("\(travelTimeString()) drive \n to arrive at \(destination)")
                                    .font(.system(size: 16, weight: .light, design: .monospaced))
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(Color.primary)
                                //.padding()
                            }
                        }
                        // Display Time to Leave and ETA
                        if useArrivalTime, let timeToLeave = timeToLeave {
                            Text("To make it by \(timeString(from: arrivalTime)), \n leave by \(timeString(from: timeToLeave))")
                                .font(.system(size: 22, weight: .medium, design: .monospaced))
                                .multilineTextAlignment(.center)
                                .foregroundColor(Color.primary)
                                .padding()
                        } else if let eta = eta {
                            Text("\(destination) ETA: \(timeString(from: eta))")
                                .font(.system(size: 22, weight: .medium, design: .monospaced))
                                .multilineTextAlignment(.center)
                                .foregroundColor(Color.primary)
                                .padding()
                            
                        }
                    }
                        
                        
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    //.background(Color.clear)  // Optional background color if needed
                    
                    .gesture(DragGesture())  // Prevent ScrollView from hijacking TabView swipe
                    
                    //scroll gesture stuff wrapp
                    .tag(1)
                
            
            
            
            //third tab
            GeometryReader { geometry in
                ScrollView {
                    
                    VStack {
                        
                        //display current time in a format defined later
                        Text(timeString(from: currentTime))
                            .font(.system(size: sizeClass == .compact ? 93 : 120, weight: .bold, design: .monospaced))
                        
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color.primary)
                            .padding(50)
                        
                        //display the date
                        Text(dateString(from: date))
                            .font(.system(size: sizeClass == .compact ? 30 : 45, weight: .bold, design: .monospaced))
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color.primary)
                            .padding(.vertical, 10)
                        
                        // Display ETA Result
                        // Display how long to get to destination
                        if travelTimeInSeconds > 0 {
                            // Display time to destination
                            if travelTimeInSeconds < 2 {
                                Text("You're already here!")
                                    .font(.system(size: 24, weight: .medium, design: .monospaced))
                                    .foregroundColor(.teal)
                                    .padding()
                            } else {
                                Text("\(travelTimeString()) drive \n to arrive at \(destination)")
                                    .font(.system(size: 16, weight: .light, design: .monospaced))
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(Color.primary)
                                //.padding()
                            }
                        }
                        // Display Time to Leave and ETA
                        if useArrivalTime, let timeToLeave = timeToLeave {
                            Text("To make it by \(timeString(from: arrivalTime)), \n leave by \(timeString(from: timeToLeave))")
                                .font(.system(size: 22, weight: .medium, design: .monospaced))
                                .multilineTextAlignment(.center)
                                .foregroundColor(Color.primary)
                                .padding()
                        } else if let eta = eta {
                            Text("\(destination) ETA: \(timeString(from: eta))")
                                .font(.system(size: 22, weight: .medium, design: .monospaced))
                                .multilineTextAlignment(.center)
                                .foregroundColor(Color.primary)
                                .padding()
                        }
                        
                        
                            // Option to use arrival time
                            Toggle("Set Desired Arrival Time", isOn: $useArrivalTime)
                                .multilineTextAlignment(.center)
                                .foregroundColor(Color.primary)
                                .padding()
                            
                            if useArrivalTime {
                                // User Input for Desired Arrival Time (only if enabled)
                                DatePicker("Desired Arrival Time", selection: $arrivalTime, displayedComponents: [.date, .hourAndMinute])
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(Color.primary)
                                    .padding()
                            }
                            
                            // User Input for Destination
                            TextField("Enter Destination", text: $destination, onEditingChanged: { _ in
                                checkDestinationField()
                            }, onCommit: {
                                calculateETA()  // Trigger the calculation when Enter key is pressed
                            })
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color.primary)
                            .padding()
                            .focused($isTextFieldFocused)  // Bind the text field focus state
                            .onTapGesture {
                                isKeyboardVisible = true
                            }
                            // Button to Trigger ETA Calculation
                            Button(action: {
                                calculateETA()
                            }) {
                                Text("Calculate ETA")
                                    .font(.body)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(Color.primary)
                                    .padding(3)
                            }
                            .padding()
                            
                            // Toggle to enable/disable notifications
                            Toggle("Notify Me When It's Time to Leave", isOn: $notificationsEnabled)
                                .multilineTextAlignment(.center)
                                .foregroundColor(Color.primary)
                                .padding()
                            
                            HStack {
                                
                            }
                            .padding()
                            
                            
                        }
                        
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    //.background(Color.clear)  // Optional background color if needed
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)  // Center vertically & horizontally
                    
                    .gesture(DragGesture())  // Prevent ScrollView from hijacking TabView swipe
                    .onTapGesture {
#if canImport(UIKit)
                        hideKeyboard() //only call if on IOS
#endif
                    }
                    //scroll gesture stuff wrapp
                    .tag(2)
            
            }
            
            
            
            
            
            
            //4th how will you get live time to update
            //when the signal comes in, update the time
            .onAppear {
                // Request notification permission when the app starts
                NotificationManager.shared.requestAuthorization()
                
                // Prevent iOS screen from turning off
#if canImport(UIKit)
                UIApplication.shared.isIdleTimerDisabled = true
#endif
                NotificationCenter.default.addObserver(forName: .locationDidChange, object: nil, queue: .main) { _ in
                    calculateETA()
                }
            }
            .onReceive(timer) { input in
                self.currentTime = input
                // If ETA is set, add the elapsed time to the ETA to keep it updated
                
                //possible redundant block
                //if eta != nil {
                // Calculate the new ETA by adding the elapsed time to the travel time
                //self.eta = //Date().addingTimeInterval(travelTimeInSeconds)
                //}
                
            }
        }
#if os(iOS)
        .tabViewStyle(PageTabViewStyle())  // Use PageTabViewStyle on iOS for swipeable tabs
#elseif os(macOS)
        .tabViewStyle(DefaultTabViewStyle())  // Use DefaultTabViewStyle on macOS
#endif  // Allows swipe between clock and ETA info
    }
    
    //5th do the calculation to repeat & update automatically
    //the clock format defined here
    func timeString(from date: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        //formatter.timeZone = TimeZone(identifier: "America/New_York")
        
        // Show date if arrival or ETA is on a different day than today
        if !calendar.isDateInToday(date) {
            formatter.dateStyle = .short
        }
        //then show the stuff
        return formatter.string(from: date)
    }
    
    //the date format defined here
    func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        //then show the stuff
        return formatter.string(from: date)
    }
    
    // Helper function to format the time or date, showing date only if it's a different day
    func formattedTime(from date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        // Check if the date is on the same day as the current time
        if calendar.isDate(date, inSameDayAs: currentTime) {
            formatter.timeStyle = .short  // Show only time (e.g., "10:45 AM")
        } else {
            formatter.dateStyle = .short  // Show date (e.g., "10/06/2024")
            formatter.timeStyle = .short  // Show time (e.g., "10:45 AM")
        }
        return formatter.string(from: date)
    }
    
    // Helper function to display travel time in minutes or hours
    func travelTimeString() -> String {
        let minutes = Int(travelTimeInSeconds / 60)
        if minutes < 60 {
            return "\(minutes) minutes"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours) hours \(remainingMinutes) minutes"
        }
    }
    
    // Function to check if the destination field is cleared and reset ETA if needed
    func checkDestinationField() {
        if destination.isEmpty {
            // Clear the timeToLeave when destination is cleared
            timeToLeave = nil
            eta = nil
            travelTimeInSeconds = 0
        }
    }
    
    // Function to calculate ETA based on current location and destination
    func calculateETA() {
        // Ensure we have a valid current location and destination
        guard let currentLocation = locationManager.currentLocation else {
            print("Unable to get current location")
            return
        }
        
        guard !destination.isEmpty else {
            print("Please enter a destination")
            return
        }
        
        // Create a request to search for the destination using the user's input
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = destination  // Use the destination variable
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response, let destinationMapItem = response.mapItems.first else {
                print("Destination not found")
                //self.eta = "Destination not found"
                return
            }
            
            // Create placemarks for source (current location) and destination
            let sourcePlacemark = MKPlacemark(coordinate: currentLocation)
            let destinationPlacemark = destinationMapItem.placemark
            
            // Create the direction request
            let directionRequest = MKDirections.Request()
            directionRequest.source = MKMapItem(placemark: sourcePlacemark)
            directionRequest.destination = MKMapItem(placemark: destinationPlacemark)
            directionRequest.transportType = .automobile  // Set transport type to driving
            
            // Get directions and calculate ETA
            let directions = MKDirections(request: directionRequest)
            directions.calculateETA { response, error in
                if let etaResponse = response {
                    // Set travel time in seconds and calculate the arrival time (ETA)
                    self.travelTimeInSeconds = etaResponse.expectedTravelTime  // Store travel time in seconds
                    
                    // If the distance is very small, show "You're already here"
                    if etaResponse.expectedTravelTime == 0 {
                        self.travelTimeInSeconds = 0
                    }
                    
                    if useArrivalTime {
                        self.timeToLeave = arrivalTime.addingTimeInterval(-self.travelTimeInSeconds)
                    } else {
                        // Set the initial ETA based on the current time
                        self.eta = Date().addingTimeInterval(self.travelTimeInSeconds)
                    }
                    // end Calculate the "time to leave" stuff
                    
                } else {
                    print("Error calculating ETA")
                }
                // Schedule notification for the time to leave
                if let timeToLeave = self.timeToLeave {
                    NotificationManager.shared.scheduleNotification(at: timeToLeave)
                }
            }
        }
    }
}


// Extension to detect location changes
extension Notification.Name {
    static let locationDidChange = Notification.Name("locationDidChange")
    
    
    // Helper function to format the ETA based on whether it's on the same day
    func formattedETA(from eta: Date) -> String {
        let calendar = Calendar.current
        let currentDay = calendar.isDateInToday(eta)  // Check if the ETA is on the same day
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short  // Always show the time (e.g., "10:45 AM")
        
        if !currentDay {
            // If ETA is not on the same day, you can choose to add the date (optional)
            formatter.dateStyle = .short  // Example: "MM/dd"
        }
        
        return formatter.string(from: eta)
    }
    
}



//6th view the ui stuff
//see the app
struct ContentView: View {
    var body: some View {
        ClockETAView() //embeds clock into main view
    }
}

#Preview {
    ContentView()
    //.modelContainer(for: Item.self, inMemory: true)
}
