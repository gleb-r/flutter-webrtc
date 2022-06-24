//
//  Square.swift
//  flutter_webrtc
//
//  Created by MacBook 16 on 17.06.2022.
//

import Foundation


public class Square: NSObject {
    let x: Int
    let y: Int
    
   @objc public init(_ x:Int,_ y:Int) {
        self.x = x
        self.y = y
    }
    
    func toMap() -> [String:NSNumber] {
        return [
            "x": NSNumber(value: x),
            "y": NSNumber(value: y)
        ]
    }
    
    func toString() -> String {
        return "\(x):\(y)"
    }
}
