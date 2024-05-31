//
//  DetectionRequest.swift
//  flutter_webrtc
//
//  Created by MacBook 16 on 03.06.2022.
//

import Foundation
import OSLog

public class DetectionRequest: NSObject {
    @objc public let enabled: Bool
    let level: Int
    
    init(enabled: Bool, level: Int) {
        self.enabled = enabled
        self.level = level
        super.init()
    }
    
  
    
    @objc  public static  func from(args: [String: Any]) -> DetectionRequest? {
        guard  let enabled = args["enabled"] as? NSNumber,
               let level = args["level"] as? NSNumber else {
            return nil
        }
        return DetectionRequest(enabled: enabled.boolValue, level: level.intValue)
    }
    
}

class Log {
    init(subsystem: String, category: String) {
        self.subsystem = subsystem
        self.category = category
    }

    let subsystem:String
    let category:String


    private lazy var logger:LogProtocol = {
        if #available(iOS 14.0, *) {
            LogNormal(subsystem: subsystem, category: category)
        } else {
            LogOldApi(subsystem: subsystem, category: category)
        }
    }()

    func d(_ message:String) {
        logger.debug(message)
    }

    func w(_ message: String) {
        logger.warning(message)
    }

    func e(_ message: String) {
        logger.error(message)
    }
}

protocol LogProtocol {
    init(subsystem: String, category: String)

    func debug (_ message: String)
    func warning(_ message: String)
    func error(_ message: String)
}

@available(iOS 14.0, *)
class LogNormal: LogProtocol {

    required init(subsystem: String, category: String) {
        self.subsystem = subsystem
        self.category = category
    }

    let subsystem:String
    let category:String


    func debug(_ message: String) {
        logger.debug("\(message)")
    }

    func error(_ message: String) {
        logger.error("\(message)")
    }


    private lazy var logger = Logger.init(subsystem: subsystem , category: category)
    func warning(_ message: String) {
        logger.warning("\(message)")
    }


}

class LogOldApi: LogProtocol {
    required init(subsystem: String, category: String) {
        self.subsystem = subsystem
        self.category = category
    }

    let subsystem:String
    let category:String



    func debug(_ message: String) {
        NSLog("[\(subsystem)] \(message)")
    }

    func error(_ message: String) {
        NSLog("[\(subsystem)] \(message)")
    }

    func warning(_ message: String) {
        NSLog("[\(subsystem)] \(message)")
    }

}
