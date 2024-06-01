//
//  DetectionWithTime.swift
//  flutter_webrtc
//
//  Created by MacBook 16 on 17.06.2022.
//

import Foundation

struct DetectionData {
    var frames: [String:[Square]]
    let aspect: Double
    let xSqCount: Int
    let ySqCount: Int
    
    init(detectionResult: DetectionResult, frameIndex: Int) {
        self.frames = ["\(frameIndex)": detectionResult.detectedList]
        self.aspect = detectionResult.aspectRatio
        self.xSqCount = detectionResult.xCount
        self.ySqCount = detectionResult.yCount
    }
    
    mutating func addDetection(detection: DetectionResult, frameIndex: Int) throws {
        guard xSqCount == detection.xCount,
              ySqCount == detection.yCount,
              aspect == detection.aspectRatio else {
            throw NSException(name: "VideoRecord error",
                              reason: "DetectionData: aspect or xSqCount or ySqCount mismatch")
        }
        frames["\(detection.frameIndex)"] = detection.detectedList
    }
    
    
    
    func toMap() -> [String: Any] {
        let framesJson = frames.mapValues({squares in squares.map({sq in sq.toString()})})
        return [
            "f": framesJson,
            "a": NSNumber(value: aspect),
            "x": NSNumber(value: xSqCount),
            "y": NSNumber(value: ySqCount)
        ]
    }
}

