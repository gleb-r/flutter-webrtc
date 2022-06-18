//
//  DetectionWithTime.swift
//  flutter_webrtc
//
//  Created by MacBook 16 on 17.06.2022.
//

import Foundation

struct DetectionWithTime {
    let squaresList: [Square]
    let time: Int
    
    func toMap() -> [String: Any] {
        return [
            "l": squaresList.map({sq in sq.toMap()}),
            "t": NSNumber(value: time)
        ]
    }
}

