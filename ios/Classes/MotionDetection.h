//
//  MotionDetection.h
//  flutter_webrtc
//
//  Created by MacBook 16 on 28.05.2022.
//

#ifndef MotionDetection_h
#define MotionDetection_h


#endif /* MotionDetection_h */

#import <Flutter/Flutter.h>
#import <WebRTC/WebRTC.h>

@interface MotionDetection : NSObject<RTCVideoRenderer>
-(instancetype) init;
-(void) startDetection: (RTCVideoTrack*) track;

@end
