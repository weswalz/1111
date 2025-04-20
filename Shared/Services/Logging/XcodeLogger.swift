//
//  XcodeLogger.swift
//  LED Messenger
//
//  Created on April 17, 2025
//

import Foundation
import os.log

/// An implementation of the LoggingService that logs to Xcode's console
/// using the unified logging system (os.log)
public class XcodeLogger: LoggingService {
    
    // MARK: - Properties
    
    /// The subsystem identifier for the logger, typically the bundle identifier
    private let subsystem: String
    
    /// The minimum log level to record (any logs below this level will be ignored)
    public var minimumLogLevel: LogLevel = .debug
    
    /// Set of categories that are enabled for logging
    public var enabledCategories: Set<LogCategory> = Set(LogCategory.allCases)
    
    /// Whether to include the call site information (file, function, line) in log messages
    public var includeCallSiteInfo: Bool = true
    
    /// Dictionary of OSLoggers keyed by category
    private var loggers: [LogCategory: OSLog] = [:]
    
    // MARK: - Initialization
    
    /// Initialize the Xcode logger with the specified subsystem
    /// - Parameter subsystem: The subsystem identifier, typically the bundle identifier
    public init(subsystem: String) {
        self.subsystem = subsystem
        
        // Pre-create loggers for each category
        for category in LogCategory.allCases {
            loggers[category] = OSLog(subsystem: subsystem, category: category.rawValue)
        }
    }
    
    // MARK: - LoggingService Implementation
    
    public func log(
        _ message: String,
        level: LogLevel,
        category: LogCategory,
        file: String,
        function: String,
        line: Int
    ) {
        // Skip if below minimum log level or category is disabled
        guard level >= minimumLogLevel, enabledCategories.contains(category) else {
            return
        }
        
        // Get the logger for this category
        let logger = loggers[category] ?? OSLog(subsystem: subsystem, category: category.rawValue)
        
        // Format the log message
        let formattedMessage = formatLogMessage(
            message: message,
            level: level,
            category: category,
            file: file,
            function: function,
            line: line
        )
        
        // Convert LogLevel to OSLogType
        let logType: OSLogType
        switch level {
        case .debug:
            logType = .debug
        case .info:
            logType = .info
        case .warning:
            logType = .default
        case .error:
            logType = .error
        case .critical:
            logType = .fault
        }
        
        // Send to os.log system
        os_log("%{public}@", log: logger, type: logType, formattedMessage)
    }
    
    // MARK: - Private Methods
    
    /// Formats a log message with additional metadata
    /// - Parameters:
    ///   - message: The raw message to format
    ///   - level: The log level
    ///   - category: The log category
    ///   - file: The source file
    ///   - function: The function name
    ///   - line: The line number
    /// - Returns: A formatted log message string
    private func formatLogMessage(
        message: String,
        level: LogLevel,
        category: LogCategory,
        file: String,
        function: String,
        line: Int
    ) -> String {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let filename = URL(fileURLWithPath: file).lastPathComponent
        
        var parts: [String] = []
        
        // Add timestamp
        parts.append("[\(timestamp)]")
        
        // Add level information with emoji
        parts.append("[\(level.emoji) \(level.description)]")
        
        // Add category with icon
        parts.append("[\(category.icon) \(category.rawValue)]")
        
        // Add call site information if enabled
        if includeCallSiteInfo {
            parts.append("[\(filename):\(function):\(line)]")
        }
        
        // Add the actual message
        parts.append(message)
        
        // Join all parts with a space
        return parts.joined(separator: " ")
    }
}
