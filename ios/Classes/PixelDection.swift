//
//  PixelDection.swift
//  flutter_webrtc
//
//  Created by MacBook 16 on 28.05.2022.
//

import Foundation
import CoreMedia
import CoreVideo

public class PixelDetection: NSObject {
    private let xBoxes = 16
    private let yBoxes = 12
    private var xBoxSize = 0
    private var yBoxSize = 0
    private var box = CGRect.zero
    private var aspectRatio: Double = 1

    private var prevMatrix: [[Int]]?
    private var prevRotation: Int = 0
    private var prevWidth = 0
    private var prevHeight = 0

    private var sizeNotChanged = false

    var xCount: Int {
        switch prevRotation {
        case 90, 270: return yBoxes
        default: return xBoxes
        }
    }

    var yCount: Int {
        switch prevRotation {
        case 90, 270: return xBoxes
        default: return yBoxes
        }
    }

    func detect(buffer: CVPixelBuffer,
                rotation: Int,
                detectionLevel: Int,
                result: @escaping ((DetectionFrame) -> Void)) {
        let width = CVPixelBufferGetWidth(buffer)
        let height = CVPixelBufferGetHeight(buffer)
        let detectionDiff = getDiff(level: detectionLevel)
        sizeNotChanged = width == prevWidth && height == prevHeight && prevRotation == rotation
        if !sizeNotChanged {
            prevWidth = width
            prevHeight = height
            prevRotation = rotation
            xBoxSize = width / xBoxes
            yBoxSize = height / yBoxes
            aspectRatio = getAspectRatio(width: width, height: height, rotation: rotation)
        }
        var currentMatrix = Array(repeating: Array(repeating: 0, count: xBoxes), count: yBoxes)

        var squareList = [Square]()
        for y in 0..<yBoxes {
            for x in 0..<xBoxes {
                let luma = averageBoxLuma(pixelBuffer: buffer, xBoxNum: x, yBoxNum: y)
                currentMatrix[y][x] = luma
                if sizeNotChanged, let prevMatrix = prevMatrix {
                    let prevLuma = prevMatrix[y][x]
                    if abs(prevLuma - luma) > detectionDiff {
                        let square = Square(x, y).rotate(rotation: rotation, xCount: xBoxes, yCount: yBoxes)
                        squareList.append(square)
                    }
                }
            }
        }
        prevMatrix = currentMatrix

        result(DetectionFrame(detectedList: squareList,
                              aspectRatio: aspectRatio,
                              xCount: xCount,
                              yCount: yCount))
    }

    func resetPrevious() {
        prevRotation = 0
        prevWidth = 0
        prevHeight = 0
        prevMatrix = nil
    }

    private func averageBoxLuma(pixelBuffer: CVPixelBuffer, xBoxNum: Int, yBoxNum: Int) -> Int {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard let baseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0) else {
            return 0
        }

        let rowStride = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)
        var color = 0
        let pixelsInBox = xBoxSize * yBoxSize
        let xOffset = yBoxNum * yBoxSize * rowStride
        let yOffset = xBoxNum * xBoxSize
        for y in 0..<yBoxSize {
            for x in 0..<xBoxSize {
                let index = yOffset + y * rowStride + xOffset + x
                color += Int(baseAddress.load(fromByteOffset: index, as: UInt8.self))
            }
        }
        return color / pixelsInBox
    }

    private func getAspectRatio(width: Int, height: Int, rotation: Int) -> Double {
        switch rotation {
        case 90, 270: return Double(height) / Double(width)
        default: return Double(width) / Double(height)
        }
    }

    private func getDiff(level: Int) -> Int {
        switch level {
        case 1: return 25
        case 2: return 14
        case 3: return 5
        case 4: return 3
        case 5: return 2
        default: return 5
        }
    }
}

extension Square {
    func rotate(rotation: Int, xCount: Int, yCount: Int) -> Square {
        switch rotation {
        case 90: return Square(yCount - y - 1, x)
        case 180: return Square(xCount - x - 1, yCount - y - 1)
        case 270: return Square(y, xCount - x - 1)
        default: return self
        }
    }
}
