//
//  DetectionWithTime.swift
//  flutter_webrtc
//
//  Created by MacBook 16 on 17.06.2022.
//

import Foundation

struct DetectionWithTime {
    let squaresList: [Square]
    let frameIndex: Int
    let aspect: Double
    let xSqCount: Int
    let ySqCount: Int
    
    func toMap() -> [String: Any] {
        return [
            "l": squaresList.map({sq in sq.toString()}),
            "i": NSNumber(value: frameIndex),
            "a": NSNumber(value: aspect),
            "x": NSNumber(value: xSqCount),
            "y": NSNumber(value: ySqCount)
        ]
    }
}

