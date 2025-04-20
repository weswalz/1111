//
//  LogManager.swift
//  LED Messenger
//
//  Created on April 17, 2025
//

import Foundation

/// Singleton class for global access to the logging service
/// Acts as a centralized entry point for logging throughout the application
public class LogManager {
    
    // MARK: - Singleton
    
    /// The shared instance of the LogManager
    public static let shared = LogManager()
    
    // MARK: - Properties
    
    /// The underlying logging service implementation
    private var loggingService: LoggingService
    
    /// The minimum log level that will be processed
    public var minimumLogLevel: LogLevel {
        get { loggingService.minimumLogLevel }
        set { loggingService.minimumLogLevel = newValue }
    }
    
    /// The categories enabled for logging
    public var enabledCategories: Set<LogCategory> {
        get { loggingService.enabledCategories }
        set { loggingService.enabledCategories = newValue }
    }
    
    /// Whether to include call site information in logs
    public var includeCallSiteInfo: Bool {
        get { loggingService.includeCallSiteInfo }
        set { loggingService.includeCallSiteInfo = newValue }
    }
    
    // MARK: - Initialization
    
    private init() {
        #if DEBUG
        // In debug builds, log everything
        let logger = XcodeLogger(subsystem: Bundle.main.bundleIdentifier ?? "com.ledmessenger")
        logger.minimumLogLevel = .debug
        logger.enabledCategories = Set(LogCategory.allCases)
        logger.includeCallSiteInfo = true
        self.loggingService = logger
        #else
        // In release builds, log warnings and above, exclude some categories
        let logger = XcodeLogger(subsystem: Bundle.main.bundleIdentifier ?? "com.ledmessenger")
        logger.minimumLogLevel = .warning
        var categories = Set(LogCategory.allCases)
        categories.remove(.debug)
        logger.enabledCategories = categories
        logger.includeCallSiteInfo = false
        self.loggingService = logger
        #endif
        
        // Log that the logging system has been initialized
        debug("Logging system initialized", category: .app)
    }
    
    /// Initialize the LogManager with a custom logging service
    /// - Parameter loggingService: The logging service to use
    public func configure(with loggingService: LoggingService) {
        self.loggingService = loggingService
        debug("Logging system reconfigured", category: .app)
    }
    
    // MARK: - Logging Methods
    
    /// Log a debug message
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: The category of the log entry
    ///   - file: The source file (automatically provided)
    ///   - function: The function name (automatically provided)
    ///   - line: The line number (automatically provided)
    public func debug(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        loggingService.debug(message, category: category, file: file, function: function, line: line)
    }
    
    /// Log an info message
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: The category of the log entry
    ///   - file: The source file (automatically provided)
    ///   - function: The function name (automatically provided)
    ///   - line: The line number (automatically provided)
    public func info(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        loggingService.info(message, category: category, file: file, function: function, line: line)
    }
    
    /// Log a warning message
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: The category of the log entry
    ///   - file: The source file (automatically provided)
    ///   - function: The function name (automatically provided)
    ///   - line: The line number (automatically provided)
    public func warning(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        loggingService.warning(message, category: category, file: file, function: function, line: line)
    }
    
    /// Log an error message
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: The category of the log entry
    ///   - file: The source file (automatically provided)
    ///   - function: The function name (automatically provided)
    ///   - line: The line number (automatically provided)
    public func error(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        loggingService.error(message, category: category, file: file, function: function, line: line)
    }
    
    /// Log a critical message
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: The category of the log entry
    ///   - file: The source file (automatically provided)
    ///   - function: The function name (automatically provided)
    ///   - line: The line number (automatically provided)
    public func critical(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        loggingService.critical(message, category: category, file: file, function: function, line: line)
    }
}

// MARK: - Global Convenience Functions

/// Global debug log function for easy access throughout the app
/// - Parameters:
///   - message: The message to log
///   - category: The category of the log entry
///   - file: The source file (automatically provided)
///   - function: The function name (automatically provided)
///   - line: The line number (automatically provided)
public func logDebug(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
    LogManager.shared.debug(message, category: category, file: file, function: function, line: line)
}

/// Global info log function for easy access throughout the app
/// - Parameters:
///   - message: The message to log
///   - category: The category of the log entry
///   - file: The source file (automatically provided)
///   - function: The function name (automatically provided)
///   - line: The line number (automatically provided)
public func logInfo(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
    LogManager.shared.info(message, category: category, file: file, function: function, line: line)
}

/// Global warning log function for easy access throughout the app
/// - Parameters:
///   - message: The message to log
///   - category: The category of the log entry
///   - file: The source file (automatically provided)
///   - function: The function name (automatically provided)
///   - line: The line number (automatically provided)
public func logWarning(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
    LogManager.shared.warning(message, category: category, file: file, function: function, line: line)
}

/// Global error log function for easy access throughout the app
/// - Parameters:
///   - message: The message to log
///   - category: The category of the log entry
///   - file: The source file (automatically provided)
///   - function: The function name (automatically provided)
///   - line: The line number (automatically provided)
public func logError(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
    LogManager.shared.error(message, category: category, file: file, function: function, line: line)
}

/// Global critical log function for easy access throughout the app
/// - Parameters:
///   - message: The message to log
///   - category: The category of the log entry
///   - file: The source file (automatically provided)
///   - function: The function name (automatically provided)
///   - line: The line number (automatically provided)
public func logCritical(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
    LogManager.shared.critical(message, category: category, file: file, function: function, line: line)
}
