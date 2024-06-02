//
//  RecordingResult.swift
//  flutter_webrtc
//
//  Created by MacBook 16 on 24.06.2022.
//

import Foundation
import Flutter

typealias  Json = [String:Any?]

struct RecordingResult{
    let recordId: String
    let videoPath: String
    let durationMs:Int
    let frameInterval:Int
    let rotationDegree:Int
    let detectionData: DetectionData?
    
    
    func toJson() -> [String: Any?] {
        return [
            "recordId": recordId,
            "video": videoPath,
            "rotation": NSNumber(value: rotationDegree),
            "duration": NSNumber(value: durationMs),
            "interval": NSNumber(value: frameInterval),
            "detection": detectionData?.toMap()
        ]
    }
}

struct RecordEvent {
    let type: RecordEventType
    let data: Json?
    
        func toJson() -> Json {
        var json:Json = ["type": type.rawValue]
        if let data = data {
            json.updateValue(data, forKey: "data")
        }
        return json
    }
}

enum RecordEventType:String {
    case idle
    case starting
    case recording
    case stop
    case result
    case error
    
    
    static func from(_ state: RecorderState) -> RecordEventType {
        switch state {
        case .idle:
            return .idle
        case .start , .initialazing:
            return .starting
        case .capturing:
            return .recording
        case .stop:
            return .stop
        }
    }
}

extension FlutterError {
    func  toJson() -> Json {
        var json = ["code":self.code]
        if let message = message {
            json.updateValue(message, forKey: "message")
        }
        if let details = details {
            json.updateValue("\(details)", forKey: "details")
        }
        return json
    }
}
