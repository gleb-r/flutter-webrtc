//
//  FlutterRTCVideoRecorder.m
//  flutter_webrtc
//
//  Created by MacBook 16 on 14.04.2022.
//

#import <Foundation/Foundation.h>
#import "FlutterRTCVideoRecorder.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CGImage.h>
#import <WebRTC/WebRTC.h>
#import <WebRTC/RTCYUVPlanarBuffer.h>
#import <WebRTC/RTCYUVHelper.h>


#import <objc/runtime.h>


@implementation FlutterRTCVideoRecorder
RTCVideoTrack* videoTrack;
NSURL *videoURL;
AVAssetWriter *videoWriter;
CVPixelBufferRef _pixelBufferRef;
CGSize _frameSize;
AVAssetWriterInput *writerInput;
AVAssetWriterInputPixelBufferAdaptor *adaptor;

bool started;

int i;

-(instancetype) init {
    if (self = [super init]) {
        _frameSize = CGSizeZero;
        started = false;
    }
    
    return self;
}



-(void) startCapture: (RTCVideoTrack *) track toPath:(NSString *)path
              result:(FlutterResult) result {
    if (started) {
        NSLog(@"Recodring already started");
        result(@NO);
        return;
    }
    videoTrack = track;
    videoURL = [NSURL fileURLWithPath:path];
    NSError *error = nil;
    videoWriter = [[AVAssetWriter alloc] initWithURL:videoURL
                                            fileType:AVFileTypeMPEG4
                                               error:&error];
    [videoTrack addRenderer:self];
    
    result(@YES);
}

-(void) createWriter: (CGSize) frameSize {
    if (started) return;
    NSNumber *width = [NSNumber numberWithDouble:frameSize.width];
    NSNumber * height = [NSNumber numberWithDouble:frameSize.height];
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264 ,
                                   AVVideoCodecKey,
                                   width,
                                   AVVideoWidthKey,
                                   height,
                                   AVVideoHeightKey,
                                   nil];
    writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    
    adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput
                                                                               sourcePixelBufferAttributes:nil];
    NSParameterAssert(writerInput);
    NSParameterAssert([videoWriter canAddInput:writerInput]);
    [videoWriter addInput:writerInput];
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];

    NSParameterAssert(videoWriter);
    
    i = 0;
    started = true;
}

-(void ) stopCaputre: (FlutterResult) result {
    if (videoTrack == nil) {
        result(@NO);
        return;
    }
    [videoTrack removeRenderer:self];
    if (!started) {
        result(@YES);
        return;
    }
    started = false;
    [writerInput markAsFinished];
    [videoWriter finishWritingWithCompletionHandler:^{
        if (videoWriter.status == AVAssetWriterStatusFailed) {
            NSLog(@"Video writing failed:%@", videoWriter.error);
        }
    }];
    CVPixelBufferPoolRelease(adaptor.pixelBufferPool);
    videoTrack = nil;
    videoWriter = nil;
    adaptor = nil;
    result(@YES);
}

- (void)renderFrame:(nullable RTCVideoFrame *)frame {
    if (_pixelBufferRef == nil) {
        NSLog(@"Render frame skpped, no pixel buffer");
        return;
    }
    if (!started) {
//        NSLog(@"Render frame skipped, Not started");
        return;
    }
    if (!writerInput.readyForMoreMediaData){
//        NSLog(@"Render frame Not ready for more mediaData, skipped");
        return;
    }
    
    
    CMTime peresentTime = CMTimeMake(i * 25, 600);
    i++;
    [self copyI420ToCVPixelBuffer:_pixelBufferRef withFrame:frame];
    [adaptor appendPixelBuffer:_pixelBufferRef withPresentationTime:peresentTime];
    
}

-(void)dealloc {
    if(_pixelBufferRef){
        CVBufferRelease(_pixelBufferRef);
    }
}

-(void)copyI420ToCVPixelBuffer:(CVPixelBufferRef)outputPixelBuffer withFrame:(RTCVideoFrame *) frame
{
    id<RTCI420Buffer> i420Buffer = [self correctRotation:[frame.buffer toI420] withRotation:frame.rotation];
    CVPixelBufferLockBaseAddress(outputPixelBuffer, 0);
    
    const OSType pixelFormat = CVPixelBufferGetPixelFormatType(outputPixelBuffer);
    if (pixelFormat == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange ||
        pixelFormat == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) {
        // NV12
        uint8_t* dstY = CVPixelBufferGetBaseAddressOfPlane(outputPixelBuffer, 0);
        const size_t dstYStride = CVPixelBufferGetBytesPerRowOfPlane(outputPixelBuffer, 0);
        uint8_t* dstUV = CVPixelBufferGetBaseAddressOfPlane(outputPixelBuffer, 1);
        const size_t dstUVStride = CVPixelBufferGetBytesPerRowOfPlane(outputPixelBuffer, 1);
        
        [RTCYUVHelper I420ToNV12:i420Buffer.dataY
                      srcStrideY:i420Buffer.strideY
                            srcU:i420Buffer.dataU
                      srcStrideU:i420Buffer.strideU
                            srcV:i420Buffer.dataV
                      srcStrideV:i420Buffer.strideV
                            dstY:dstY
                      dstStrideY:(int)dstYStride
                           dstUV:dstUV
                     dstStrideUV:(int)dstUVStride
                           width:i420Buffer.width
                           width:i420Buffer.height];
    } else {
        uint8_t* dst = CVPixelBufferGetBaseAddress(outputPixelBuffer);
        const size_t bytesPerRow = CVPixelBufferGetBytesPerRow(outputPixelBuffer);
        
        if (pixelFormat == kCVPixelFormatType_32BGRA) {
            // Corresponds to libyuv::FOURCC_ARGB
            
            [RTCYUVHelper I420ToARGB:i420Buffer.dataY
                          srcStrideY:i420Buffer.strideY
                                srcU:i420Buffer.dataU
                          srcStrideU:i420Buffer.strideU
                                srcV:i420Buffer.dataV
                          srcStrideV:i420Buffer.strideV
                             dstARGB:dst
                       dstStrideARGB:(int)bytesPerRow
                               width:i420Buffer.width
                              height:i420Buffer.height];
            
        } else if (pixelFormat == kCVPixelFormatType_32ARGB) {
            // Corresponds to libyuv::FOURCC_BGRA
            [RTCYUVHelper I420ToBGRA:i420Buffer.dataY
                          srcStrideY:i420Buffer.strideY
                                srcU:i420Buffer.dataU
                          srcStrideU:i420Buffer.strideU
                                srcV:i420Buffer.dataV
                          srcStrideV:i420Buffer.strideV
                             dstBGRA:dst
                       dstStrideBGRA:(int)bytesPerRow
                               width:i420Buffer.width
                              height:i420Buffer.height];
        }
    }
    CVPixelBufferUnlockBaseAddress(outputPixelBuffer, 0);
}

-(id<RTCI420Buffer>) correctRotation:(const id<RTCI420Buffer>) src
                        withRotation:(RTCVideoRotation) rotation
{
    
    int rotated_width = src.width;
    int rotated_height = src.height;
    
    if (rotation ==  RTCVideoRotation_90 ||
        rotation == RTCVideoRotation_270) {
        int temp = rotated_width;
        rotated_width = rotated_height;
        rotated_height = temp;
    }
    
    id<RTCI420Buffer> buffer = [[RTCI420Buffer alloc] initWithWidth:rotated_width height:rotated_height];
    
    [RTCYUVHelper I420Rotate:src.dataY
                  srcStrideY:src.strideY
                        srcU:src.dataU
                  srcStrideU:src.strideU
                        srcV:src.dataV
                  srcStrideV:src.strideV
                        dstY:(uint8_t*)buffer.dataY
                  dstStrideY:buffer.strideY
                        dstU:(uint8_t*)buffer.dataU
                  dstStrideU:buffer.strideU
                        dstV:(uint8_t*)buffer.dataV
                  dstStrideV:buffer.strideV
                       width:src.width
                       width:src.height
                        mode:rotation];
    
    return buffer;
}

NSString* getCurrentTime(void) {
    NSDate* now = [NSDate date];
    NSDateFormatter* dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"HH:mm:ss:SSS"];
    return [dateFormat stringFromDate:now];
    
}

- (void)setSize:(CGSize)size {
    if (!started) {
        [self createWriter: size];
    }
    if(_pixelBufferRef == nil || (size.width != _frameSize.width || size.height != _frameSize.height))
    {
        if(_pixelBufferRef){
            CVBufferRelease(_pixelBufferRef);
        }
        NSDictionary *pixelAttributes = @{(id)kCVPixelBufferIOSurfacePropertiesKey : @{}};
        CVPixelBufferCreate(kCFAllocatorDefault,
                            size.width, size.height,
                            kCVPixelFormatType_32BGRA,
                            (__bridge CFDictionaryRef)(pixelAttributes), &_pixelBufferRef);
        
        _frameSize = size;
    }
}

@end
