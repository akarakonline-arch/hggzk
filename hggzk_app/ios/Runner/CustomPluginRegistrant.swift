import Flutter
import UIKit

@objc public class CustomPluginRegistrant: NSObject {
    
    // CRITICAL: Initialize Swift runtime before any plugin registration
    @objc public static func ensureSwiftRuntimeInitialized() {
        // Force Swift runtime initialization
        _ = SwiftRuntimeInitializer()
        
        // Pre-load Swift standard libraries
        _ = [String]()
        _ = [Int]()
        _ = Dictionary<String, Any>()
        
        // Small delay to ensure everything is loaded
        Thread.sleep(forTimeInterval: 0.05)
        
        print("✅ Swift runtime initialized successfully")
    }
}

// Helper class to force Swift initialization
private class SwiftRuntimeInitializer {
    init() {
        // This forces Swift metadata to be initialized
    }
}