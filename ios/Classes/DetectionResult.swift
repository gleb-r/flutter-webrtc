//
//  DetectionResult.swift
//  flutter_webrtc
//
//  Created by MacBook 16 on 29.05.2022.
//

import Foundation

struct DetectionResult {
    let detectedList: [LumaRect]
    let aspectRatio: Double
    
    func toMap() -> [String: Any] {
        return ["detected": detectedList.map{rect in rect.toMap()},
                "aspect": NSNumber(value: aspectRatio)
        ]
    }
    
}

struct LumaRect {
    let rect: CGRect
    let luma: Int
    
    func toMap() -> [String:NSNumber] {
        let left = NSNumber(value: rect.minX)
        let top = NSNumber(value: rect.minY)
        let right = NSNumber(value: rect.maxX)
        let bottom = NSNumber(value: rect.maxY)
        let color = NSNumber(value: luma)
        return ["l":left,
                "t":top,
                "r":right,
                "b":bottom,
                "c":color
        ]
    }
}
