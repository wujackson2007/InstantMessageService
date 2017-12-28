//
//  RtcCapture.m
//  rtcTest
//
//  Created by 吳永誌 on 2017/8/12.
//  Copyright © 2017年 1111. All rights reserved.
//

#import "RtcCapture.h"

@implementation RtcCapture {
    int captureWidth;
    int captureHeight;
    //RTCCameraVideoCapturer *_capturer;
    BOOL _usingFrontCamera;
}

@synthesize capturer = _capturer;

- (instancetype)initWithCapturer:(RTCCameraVideoCapturer *)capturer usingFrontCamera:(BOOL)usingFrontCamera {
    if ([super init]) {
        _capturer = capturer;
        _usingFrontCamera = usingFrontCamera;
    }
    
    return self;
}

- (void)startCaptureWithWidth:(int)width height:(int)height {
    AVCaptureDevicePosition position = _usingFrontCamera ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
    captureWidth = width;
    captureHeight = height;
    AVCaptureDevice *device = [self findDeviceForPosition:position];
    AVCaptureDeviceFormat *format = [self selectFormatForDevice:device targetWidth:captureWidth targetHeight:captureHeight];
    NSInteger fps = [self selectFpsForFormat:format];
    [_capturer startCaptureWithDevice:device format:format fps:fps];
}

- (void)stopCapture {
    [_capturer stopCapture];
}

- (void)switchCamera {
    _usingFrontCamera = !_usingFrontCamera;
    [self startCaptureWithWidth:captureWidth height:captureHeight];
}

#pragma mark - Private

- (AVCaptureDevice *)findDeviceForPosition:(AVCaptureDevicePosition)position {
    NSArray<AVCaptureDevice *> *captureDevices = [RTCCameraVideoCapturer captureDevices];
    for (AVCaptureDevice *device in captureDevices) {
        if (device.position == position) {
            return device;
        }
    }
    return captureDevices[0];
}

- (AVCaptureDeviceFormat *)selectFormatForDevice:(AVCaptureDevice *)device targetWidth:(int)width targetHeight:(int)height {
    NSArray<AVCaptureDeviceFormat *> *formats =
    [RTCCameraVideoCapturer supportedFormatsForDevice:device];
    AVCaptureDeviceFormat *selectedFormat = nil;
    int currentDiff = INT_MAX;
    
    for (AVCaptureDeviceFormat *format in formats) {
        CMVideoDimensions dimension = CMVideoFormatDescriptionGetDimensions(format.formatDescription);
        int diff = abs(width - dimension.width) + abs(height - dimension.height);
        if (diff < currentDiff) {
            selectedFormat = format;
            currentDiff = diff;
        }
    }
    
    NSAssert(selectedFormat != nil, @"No suitable capture format found.");
    return selectedFormat;
}

- (NSInteger)selectFpsForFormat:(AVCaptureDeviceFormat *)format {
    Float64 maxFramerate = 0;
    for (AVFrameRateRange *fpsRange in format.videoSupportedFrameRateRanges) {
        maxFramerate = fmax(maxFramerate, fpsRange.maxFrameRate);
    }
    return maxFramerate;
}


/* test */
+ (CVPixelBufferRef)pixelBufferFromImage:(CGImageRef)image {
    // Not sure why this is even necessary, using CGImageGetWidth/Height in status/context seems to work fine too
    CGSize frameSize = CGSizeMake(CGImageGetWidth(image), CGImageGetHeight(image));
    
    CVPixelBufferRef pixelBuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, frameSize.width, frameSize.height, kCVPixelFormatType_32BGRA, nil, &pixelBuffer);
    if (status != kCVReturnSuccess) {
        return NULL;
    }
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void *data = CVPixelBufferGetBaseAddress(pixelBuffer);
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(data, frameSize.width, frameSize.height, 8, CVPixelBufferGetBytesPerRow(pixelBuffer), rgbColorSpace, (CGBitmapInfo) kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image), CGImageGetHeight(image)), image);
    
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    return pixelBuffer;
}

+ (CMSampleBufferRef)createSampleBufferRef:(UIImage*)image {
    // This image is already in the testing bundle.
    CGSize size = image.size;
    CGImageRef imageRef = [image CGImage];
    
    CVPixelBufferRef pixelBuffer = nil;
    CVPixelBufferCreate(kCFAllocatorDefault, size.width, size.height, kCVPixelFormatType_32ARGB, nil,
                        &pixelBuffer);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    // We don't care about bitsPerComponent and bytesPerRow so arbitrary value of 8 for both.
    CGContextRef context = CGBitmapContextCreate(nil, size.width, size.height, 8, 8 * size.width,
                                                 rgbColorSpace, kCGImageAlphaPremultipliedFirst);
    
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(imageRef), CGImageGetHeight(imageRef)), imageRef);
    
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    // We don't really care about the timing.
    CMSampleTimingInfo timing = {kCMTimeInvalid, kCMTimeInvalid, kCMTimeInvalid};
    CMVideoFormatDescriptionRef description = nil;
    CMVideoFormatDescriptionCreateForImageBuffer(NULL, pixelBuffer, &description);
    
    CMSampleBufferRef sampleBuffer = nil;
    CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault, pixelBuffer, YES, NULL, NULL, description,
                                       &timing, &sampleBuffer);
    CFRelease(pixelBuffer);
    return sampleBuffer;
}

+ (CVPixelBufferRef)pixelBufferCopy:(CVPixelBufferRef)target
{
    CVPixelBufferRef pixelBuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault
                                          , CVPixelBufferGetWidth(target)
                                          , CVPixelBufferGetHeight(target)
                                          , CVPixelBufferGetPixelFormatType(target)
                                          , nil, &pixelBuffer);
    
    if (status != kCVReturnSuccess) {
        return NULL;
    }
    
    CVPixelBufferLockBaseAddress(target, kCVPixelBufferLock_ReadOnly);
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    memcpy(CVPixelBufferGetBaseAddress(pixelBuffer), CVPixelBufferGetBaseAddress(target), CVPixelBufferGetDataSize(target));
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    CVPixelBufferUnlockBaseAddress(target, kCVPixelBufferLock_ReadOnly);
    
    return pixelBuffer;
}

+ (RTCVideoFrame*)videoFrameFrom:(UIImage *)image
{
    RTCVideoFrame *_Frame = nil;
    RTCCVPixelBuffer *_buf = nil;
    
    CMSampleBufferRef sample_buffer = [RtcCapture createSampleBufferRef:image];
    CVImageBufferRef image_buffer = CMSampleBufferGetImageBuffer(sample_buffer);
    _buf = [[RTCCVPixelBuffer alloc] initWithPixelBuffer:image_buffer];
    
    //CVPixelBufferRef pixelBuffer = [RtcCapture pixelBufferFromImage:image.CGImage];
    //_buf = [[RTCCVPixelBuffer alloc] initWithPixelBuffer:pixelBuffer];
    
    _Frame = [[RTCVideoFrame alloc] initWithBuffer:[_buf toI420] rotation:RTCVideoRotation_0 timeStampNs:0];
    return _Frame;
}
@end
