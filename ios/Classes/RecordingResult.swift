//
//  RecordingResult.swift
//  flutter_webrtc
//
//  Created by MacBook 16 on 24.06.2022.
//

import Foundation

public class RecordingResult:NSObject {
    let filePath: String
    let durationMs:Int
    
    public init(filePath: String, durationMs: Int) {
        self.durationMs = durationMs
        self.filePath = filePath
        super.init()
    }
    
    public func toMap() ->[String: Any] {
        return ["file": filePath,
                "duration": NSNumber(value: durationMs)
        ]
    }
}
