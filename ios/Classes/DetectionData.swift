//
//  DetectionWithTime.swift
//  flutter_webrtc
//
//  Created by MacBook 16 on 17.06.2022.
//


import Foundation
import Flutter


struct DetectionData {
    var frames: [String:[Square]]
    let aspect: Double
    let xSqCount: Int
    let ySqCount: Int
    let frameIntervalMs: Int
    var duration: Int = 0
    
    init(detectionFrame: DetectionFrame,
         frameIndex: Int,
         frameIntervalMs: Int) {
        self.frames = ["\(frameIndex)": detectionFrame.detectedList]
        self.aspect = detectionFrame.aspectRatio
        self.xSqCount = detectionFrame.xCount
        self.ySqCount = detectionFrame.yCount
        self.frameIntervalMs = frameIntervalMs        
    }
    
    mutating func addDetection(detection: DetectionFrame, frameIndex: Int) throws  {
        guard xSqCount == detection.xCount,
              ySqCount == detection.yCount,
              aspect == detection.aspectRatio else {
            throw NSError(domain: "DetectionData",
                          code: 1,
                          userInfo: ["message": "Detection data is not compatible"])
        }
        frames["\(frameIndex)"] = detection.detectedList
    }
    
    
    
    func toMap() -> [String: Any] {
        let framesJson = frames.mapValues({squares in squares.map({sq in sq.toString()})})
        return [
            "frames": framesJson,
            "a": NSNumber(value: aspect),
            "x": NSNumber(value: xSqCount),
            "y": NSNumber(value: ySqCount),
            "ft": NSNumber(value: frameIntervalMs),
            "d": NSNumber(value: duration)
        ]
    }
}
