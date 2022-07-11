//
//  DetectionRequest.swift
//  flutter_webrtc
//
//  Created by MacBook 16 on 03.06.2022.
//

import Foundation

public class DetectionRequest: NSObject {
    @objc public let enabled: Bool
    let level: Int
    
    init(enabled: Bool, level: Int) {
        self.enabled = enabled
        self.level = level
        super.init()
    }
    
  
    
    @objc  public static  func from(args: [String: Any]) -> DetectionRequest? {
        guard  let enabled = args["enabled"] as? NSNumber,
               let level = args["level"] as? NSNumber else {
            return nil
        }
        return DetectionRequest(enabled: enabled.boolValue, level: level.intValue)
    }
    
}
