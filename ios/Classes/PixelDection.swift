//
//  PixelDection.swift
//  flutter_webrtc
//
//  Created by MacBook 16 on 28.05.2022.
//

import Foundation
import WebRTC


public class PixelDetection:NSObject {
    private let xBoxes = 16
    private let yBoxes = 12
    private var xBoxSize = 0
    private var yBoxSize = 0
    private var box = CGRect.zero
    private var aspectRatio: Double = 1
    
    private var prevMatrix: [[Int]]?
    private var prevRotation = RTCVideoRotation._0
    private var prevWidth = 0
    private var prevHeight = 0
    
    private var sizeNotChanged = false
    
    
    
    func detect(buffer: RTCI420BufferProtocol,
                rotation: RTCVideoRotation,
                detectionLevel: Int,
                result: @escaping ((DetectionResult) -> Void)) {
        let width = Int(buffer.width)
        let heigth = Int(buffer.height)
        let detectionDiff = getDiff(level: detectionLevel)
        sizeNotChanged = width == prevWidth && heigth == prevHeight &&  prevRotation == rotation
        if !sizeNotChanged {
            prevWidth = width
            prevHeight = heigth
            prevRotation = rotation
            xBoxSize = width / xBoxes
            yBoxSize = heigth / yBoxes
            box = CGRect(x: 0, y: 0, width: xBoxSize, height: yBoxSize)
            aspectRatio = getAspectRatio(width: width, height: heigth, rotation: rotation)
        }
        var currentMatrix = Array(repeating: Array(repeating: 0, count: xBoxes), count: yBoxes)
        var detectedList = [LumaRect]()
        for y in 0..<yBoxes {
            for x in 0..<xBoxes {
                let rect = box.move(dx: x * xBoxSize,dy: y * yBoxSize)
                    .scale(x: 1/CGFloat(width), y: 1/CGFloat(heigth))
                    .rotate(rotation: rotation)
                let luma = avetageBoxLuma(
                    yData: buffer.dataY,
                    rowStride:Int(buffer.strideY) ,
                    xBoxNum: x,
                    yBoxNum: y)
                currentMatrix[y][x] = luma
                if sizeNotChanged, let prevMatrix = prevMatrix {
                    let prevLuma = prevMatrix[y][x]
                    if abs(prevLuma - luma) > detectionDiff {
                        detectedList.append(LumaRect(rect: rect, luma: luma))
                    }
                }
            }
        }
        prevMatrix = currentMatrix
        result(DetectionResult(detectedList: detectedList, aspectRatio: aspectRatio))
    }
    
    func resetPrevious() {
        prevRotation = ._0
        prevWidth = 0
        prevHeight = 0
        prevMatrix = nil
    }
    
    
    
    private func avetageBoxLuma(yData: UnsafePointer<UInt8>,
                                rowStride: Int,
                                xBoxNum: Int,
                                yBoxNum: Int) -> Int {
        var color = 0
        let pixelsInBox = xBoxSize * yBoxSize
        let xOffset = yBoxNum * yBoxSize * rowStride
        let yOffset = xBoxNum * xBoxSize
        for y in 0..<yBoxSize {
            for x in 0..<xBoxSize {
                let index = yOffset + y * rowStride + xOffset + x
                color += Int(yData[index])
            }
        }
        return color / pixelsInBox
    }
    
    private func getAspectRatio(
        width: Int,
        height: Int,
        rotation: RTCVideoRotation) -> Double {
            switch rotation {
            case ._90:return Double(height)/Double(width)
            case ._270: return Double(height)/Double(width)
            default: return Double(width)/Double(height)
            }
        }
    
    private func getDiff(level: Int) -> Int {
        switch(level) {
        case 1: return 25
        case 2: return 14
        case 3: return 5
        case 4: return 3
        case 5: return 2
        default: return 5
        }
    }
}

extension CGRect {
    func move(dx:Int, dy: Int) -> CGRect {
        return CGRect(
            x: self.minX + CGFloat(dx),
            y: self.minY + CGFloat(dy),
            width: width,
            height: height)
    }
    
    func scale(x:CGFloat, y:CGFloat) -> CGRect {
        let xScale = CGFloat(x)
        let yScale = CGFloat(y)
        return CGRect(
            x: self.minX * xScale,
            y: self.minY * yScale,
            width: width * xScale,
            height: height * yScale)
    }
    
    func rotate(rotation:RTCVideoRotation) -> CGRect {
        
        switch rotation {
        case ._90:
            return CGRect(
                x: 1 - maxY,
                y: minX,
                width: height,
                height: width)
        case ._180:
            return CGRect(
                x: 1 - maxX,
                y: 1 - maxY,
                width: width ,
                height: height)
        default:
            return self
        }
    }
}
