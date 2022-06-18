//
//  DetectionResult.swift
//  flutter_webrtc
//
//  Created by MacBook 16 on 29.05.2022.
//

import Foundation

struct DetectionResult {
    let detectedList: [Square]
    let aspectRatio: Double
    let xCount: Int
    let yCount: Int
    
    func toMap() -> [String: Any] {
        return ["detected": detectedList.map{sq in sq.toMap()},
                "aspect": NSNumber(value: aspectRatio),
                "xCount": NSNumber(value: xCount),
                "yCount": NSNumber(value: yCount),
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
