//
//  RecordingResult.swift
//  flutter_webrtc
//
//  Created by MacBook 16 on 24.06.2022.
//

import Foundation

struct RecordingResult{
    let recordId: String
    let videoPath: String
    let durationMs:Int
    let frameInterval:Int
    let rotationDegree:Int
    
    func toMap() ->[String: Any] {
        return [
            "recordId": recordId,
            "video": videoPath,
            "rotation": NSNumber(value: rotationDegree),
            "duration": NSNumber(value: durationMs),
            "interval": NSNumber(value: frameInterval)
        ]
    }
}
