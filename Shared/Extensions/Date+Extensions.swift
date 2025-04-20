//
//  Date+Extensions.swift
//  LED Messenger
//
//  Created on April 17, 2025
//

import Foundation

// Extensions for Date manipulation and formatting
extension Date {
    
    /// Format date with standard style
    /// - Returns: Formatted date string
    public func formatted() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    /// Format date with custom style
    /// - Parameters:
    ///   - dateStyle: The date formatting style
    ///   - timeStyle: The time formatting style
    /// - Returns: Formatted date string
    public func formatted(dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        return formatter.string(from: self)
    }
    
    /// Format date with a custom format
    /// - Parameter format: The date format string
    /// - Returns: Formatted date string
    public func formatted(using format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
    
    /// Format as a relative time string (e.g. "2 hours ago")
    /// - Returns: Relative time string
    public func relativeFormatted() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    /// Format as a short relative time string (e.g. "2h ago")
    /// - Returns: Short relative time string
    public func shortRelativeFormatted() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    /// Format as time ago string with appropriate level of detail
    /// - Returns: Time ago string
    public func timeAgoFormatted() -> String {
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.minute, .hour, .day, .weekOfMonth, .month, .year], from: self, to: now)
        
        if let years = components.year, years > 0 {
            return years == 1 ? "1 year ago" : "\(years) years ago"
        }
        
        if let months = components.month, months > 0 {
            return months == 1 ? "1 month ago" : "\(months) months ago"
        }
        
        if let weeks = components.weekOfMonth, weeks > 0 {
            return weeks == 1 ? "1 week ago" : "\(weeks) weeks ago"
        }
        
        if let days = components.day, days > 0 {
            return days == 1 ? "1 day ago" : "\(days) days ago"
        }
        
        if let hours = components.hour, hours > 0 {
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        }
        
        if let minutes = components.minute, minutes > 0 {
            return minutes == 1 ? "1 minute ago" : "\(minutes) minutes ago"
        }
        
        return "Just now"
    }
    
    /// Format as a date only string
    /// - Returns: Date only string
    public func dateOnlyFormatted() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
    
    /// Format as a time only string
    /// - Returns: Time only string
    public func timeOnlyFormatted() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    /// Check if date is today
    /// - Returns: True if date is today
    public var isToday: Bool {
        return Calendar.current.isDateInToday(self)
    }
    
    /// Check if date is yesterday
    /// - Returns: True if date is yesterday
    public var isYesterday: Bool {
        return Calendar.current.isDateInYesterday(self)
    }
    
    /// Check if date is tomorrow
    /// - Returns: True if date is tomorrow
    public var isTomorrow: Bool {
        return Calendar.current.isDateInTomorrow(self)
    }
    
    /// Check if date is in the past
    /// - Returns: True if date is in the past
    public var isPast: Bool {
        return self < Date()
    }
    
    /// Check if date is in the future
    /// - Returns: True if date is in the future
    public var isFuture: Bool {
        return self > Date()
    }
    
    /// Get date with added days
    /// - Parameter days: Days to add
    /// - Returns: New date with days added
    public func adding(days: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
    
    /// Get date with added hours
    /// - Parameter hours: Hours to add
    /// - Returns: New date with hours added
    public func adding(hours: Int) -> Date {
        return Calendar.current.date(byAdding: .hour, value: hours, to: self) ?? self
    }
    
    /// Get date with added minutes
    /// - Parameter minutes: Minutes to add
    /// - Returns: New date with minutes added
    public func adding(minutes: Int) -> Date {
        return Calendar.current.date(byAdding: .minute, value: minutes, to: self) ?? self
    }
    
    /// Get the start of the day for this date
    /// - Returns: Date at start of day
    public var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    /// Get the end of the day for this date
    /// - Returns: Date at end of day
    public var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }
}
