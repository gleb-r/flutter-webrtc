//
//  FlutterRTCVideoRecorder.h
//  flutter_webrtc
//
//  Created by MacBook 16 on 13.04.2022.
//

#ifndef FlutterRTCVideoRecorder_h
#define FlutterRTCVideoRecorder_h


#endif /* FlutterRTCVideoRecorder_h */
#import <Flutter/Flutter.h>
#import <WebRTC/WebRTC.h>

@interface FlutterRTCVideoRecorder : NSObject<RTCVideoRenderer>
-(instancetype) init;
-(void) startCapture: (RTCVideoTrack *) track toPath:(NSString *)path
              result:(FlutterResult) result;
-(void ) stopCaputre: (FlutterResult) result;

@end
