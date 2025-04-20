//
//  OSCMessage.swift
//  LED Messenger
//
//  Created on April 17, 2025
//

import Foundation

/// Represents an OSC (Open Sound Control) message
public struct OSCMessage {
    
    // MARK: - Properties
    
    /// The address pattern for this message
    public let address: String
    
    /// The arguments for this message
    public let arguments: [OSCArgument]
    
    // MARK: - Initialization
    
    /// Create an OSC message with no arguments
    /// - Parameter address: The address pattern
    public init(address: String) {
        self.address = address
        self.arguments = []
    }
    
    /// Create an OSC message with arguments
    /// - Parameters:
    ///   - address: The address pattern
    ///   - arguments: The arguments to include
    public init(address: String, arguments: [OSCArgument]) {
        self.address = address
        self.arguments = arguments
    }
    
    /// Create an OSC message with variadic arguments
    /// - Parameters:
    ///   - address: The address pattern
    ///   - arguments: The arguments to include
    public init(address: String, arguments: OSCArgument...) {
        self.address = address
        self.arguments = arguments
    }
    
    // MARK: - Binary Formatting
    
    /// Convert the OSC message to a Data object for transmission
    /// - Returns: Binary representation of the OSC message
    public func toData() -> Data {
        var data = Data()
        
        // Add the address pattern
        data.append(OSCMessage.encodeString(address))
        
        // If there are arguments, add a type tag string and the arguments
        if !arguments.isEmpty {
            // Type tag string starts with ','
            var typeTagString = ","
            
            // Add a type tag for each argument
            for argument in arguments {
                typeTagString.append(argument.typeTag)
            }
            
            // Encode the type tag string
            data.append(OSCMessage.encodeString(typeTagString))
            
            // Add each argument's binary representation
            for argument in arguments {
                data.append(argument.toData())
            }
        } else {
            // If there are no arguments, add a type tag string with just ','
            data.append(OSCMessage.encodeString(","))
        }
        
        return data
    }
    
    /// Encode a string as OSC-compatible data
    /// - Parameter string: The string to encode
    /// - Returns: OSC-encoded string data
    private static func encodeString(_ string: String) -> Data {
        var data = Data()
        
        // Convert string to UTF-8 data
        if let stringData = string.data(using: .utf8) {
            data.append(stringData)
            
            // Add null terminator
            data.append(0)
            
            // Pad to multiple of 4 bytes
            let padLength = 4 - (data.count % 4)
            if padLength < 4 {
                data.append(contentsOf: [UInt8](repeating: 0, count: padLength))
            }
        }
        
        return data
    }
}

/// Represents an argument in an OSC message
public enum OSCArgument {
    case int32(Int32)
    case float32(Float)
    case string(String)
    case blob(Data)
    
    /// The type tag character for this argument
    public var typeTag: Character {
        switch self {
        case .int32:    return "i"
        case .float32:  return "f"
        case .string:   return "s"
        case .blob:     return "b"
        }
    }
    
    /// Convert the argument to binary data for OSC transmission
    /// - Returns: Binary representation of the argument
    public func toData() -> Data {
        var data = Data()
        
        switch self {
        case .int32(let value):
            // Convert Int32 to big-endian byte order
            var bigEndian = value.bigEndian
            data.append(Data(bytes: &bigEndian, count: MemoryLayout<Int32>.size))
            
        case .float32(let value):
            // Convert Float to big-endian byte order
            var bigEndian = value.bitPattern.bigEndian
            data.append(Data(bytes: &bigEndian, count: MemoryLayout<UInt32>.size))
            
        case .string(let value):
            // Encode string with OSC string format
            data.append(OSCMessage.encodeString(value))
            
        case .blob(let value):
            // For blobs, first add the size as a big-endian Int32
            var size = Int32(value.count).bigEndian
            data.append(Data(bytes: &size, count: MemoryLayout<Int32>.size))
            
            // Then add the blob data
            data.append(value)
            
            // Pad to multiple of 4 bytes
            let padLength = 4 - (value.count % 4)
            if padLength < 4 {
                data.append(contentsOf: [UInt8](repeating: 0, count: padLength))
            }
        }
        
        return data
    }
    
    /// Encode a string as OSC-compatible data
    private static func encodeString(_ string: String) -> Data {
        return OSCMessage.encodeString(string)
    }
}

/// Extensions for creating OSC arguments from Swift types
extension OSCArgument {
    /// Create an OSC argument from an Int
    /// - Parameter value: The Int value
    /// - Returns: An OSC int32 argument
    public static func from(_ value: Int) -> OSCArgument {
        return .int32(Int32(value))
    }
    
    /// Create an OSC argument from a Double
    /// - Parameter value: The Double value
    /// - Returns: An OSC float32 argument
    public static func from(_ value: Double) -> OSCArgument {
        return .float32(Float(value))
    }
    
    /// Create an OSC argument from a Bool
    /// - Parameter value: The Bool value
    /// - Returns: An OSC int32 argument (1 for true, 0 for false)
    public static func from(_ value: Bool) -> OSCArgument {
        return .int32(value ? 1 : 0)
    }
}
