//
//  LoggingService.swift
//  LED Messenger
//
//  Created on April 17, 2025
//

import Foundation
import os.log

/// Protocol defining the requirements for a logging service implementation
public protocol LoggingService {
    
    /// Log a message with specified level and category
    /// - Parameters:
    ///   - message: The message to log
    ///   - level: The severity level of the log entry
    ///   - category: The category to group this log entry under
    ///   - file: The source file where the log was called from
    ///   - function: The function where the log was called from
    ///   - line: The line number where the log was called from
    func log(
        _ message: String,
        level: LogLevel,
        category: LogCategory,
        file: String,
        function: String,
        line: Int
    )
    
    /// Debug level convenience method
    func debug(_ message: String, category: LogCategory, file: String, function: String, line: Int)
    
    /// Info level convenience method
    func info(_ message: String, category: LogCategory, file: String, function: String, line: Int)
    
    /// Warning level convenience method
    func warning(_ message: String, category: LogCategory, file: String, function: String, line: Int)
    
    /// Error level convenience method
    func error(_ message: String, category: LogCategory, file: String, function: String, line: Int)
    
    /// Critical level convenience method
    func critical(_ message: String, category: LogCategory, file: String, function: String, line: Int)
    
    /// Get the minimum log level that should be processed
    var minimumLogLevel: LogLevel { get set }
    
    /// Enable or disable specific log categories
    var enabledCategories: Set<LogCategory> { get set }
    
    /// Toggle whether file/function/line information is included in logs
    var includeCallSiteInfo: Bool { get set }
}

/// Default implementation for convenience methods
extension LoggingService {
    
    public func debug(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, category: category, file: file, function: function, line: line)
    }
    
    public func info(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, category: category, file: file, function: function, line: line)
    }
    
    public func warning(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, category: category, file: file, function: function, line: line)
    }
    
    public func error(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, category: category, file: file, function: function, line: line)
    }
    
    public func critical(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .critical, category: category, file: file, function: function, line: line)
    }
}
