#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface ScreenRecorder : NSObject <AVCaptureFileOutputRecordingDelegate>

- (void)startRecordingScreen:(NSScreen *)screen rect:(CGRect)rect saveToFileURL:(NSURL *)dst;
- (void)stop:(BOOL)blockUntilStopped;

@end

@implementation ScreenRecorder {
  AVCaptureSession *_session;
  AVCaptureMovieFileOutput *_output;
}

static CMTime RefreshRateForDisplayID(CGDirectDisplayID displayID) {
  CVDisplayLinkRef displayLink;
  assert(CVDisplayLinkCreateWithCGDisplay(displayID, &displayLink) == kCVReturnSuccess);
  CVTime refreshRate = CVDisplayLinkGetNominalOutputVideoRefreshPeriod(displayLink);
  CVDisplayLinkRelease(displayLink);
  return CMTimeMake(refreshRate.timeValue, refreshRate.timeScale);
}

- (void)startRecordingScreen:(NSScreen *)screen rect:(CGRect)rect saveToFileURL:(NSURL *)dst {
  assert(!_session);
  assert(!_output);
  AVCaptureScreenInput *input;
  CGDirectDisplayID displayID = [screen.deviceDescription[@"NSScreenNumber"] unsignedIntValue];
  assert(_session = [[AVCaptureSession alloc] init]);
  assert(input = [[AVCaptureScreenInput alloc] initWithDisplayID:displayID]);
  input.cropRect = rect;
  input.scaleFactor = 1.0/[screen backingScaleFactor];
  input.minFrameDuration = RefreshRateForDisplayID(displayID);
  assert(_output = [[AVCaptureMovieFileOutput alloc] init]);
  assert([_session canAddInput:input]);
  [_session addInput:input];
  assert([_session canAddOutput:_output]);
  [_session addOutput:_output];

  [_session startRunning];
  [[NSFileManager defaultManager] removeItemAtURL:dst error:nil];
  [_output startRecordingToOutputFileURL:dst recordingDelegate:self];
}

- (void)stop:(BOOL)blockUntilStopped {
  [_output stopRecording];
  while (_session) // nil'd when file output complete
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate distantPast]];
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput
didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL
      fromConnections:(NSArray *)connections
                error:(NSError *)error {
  if (error) NSLog(@"%@", error);
  [_session stopRunning];
  _session = nil;
  _output = nil;
}

@end

int main(int argc, const char *argv[]) {
  if (argc != 7)
    return fprintf(stderr, "Usage: record-screen x y w h duration path\n"), -1;
  @autoreleasepool {
    int x = strtol(argv[1], NULL, 10);
    int y = strtol(argv[2], NULL, 10);
    int w = strtol(argv[3], NULL, 10);
    int h = strtol(argv[4], NULL, 10);
    float duration = strtof(argv[5], NULL);
    NSString *path = [NSString stringWithUTF8String:argv[6]];
    
    ScreenRecorder *recorder = [ScreenRecorder new];
    [recorder startRecordingScreen:[NSScreen mainScreen] rect:CGRectMake(x, y, w , h) saveToFileURL:[NSURL fileURLWithPath:path]];
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:duration]];
    [recorder stop:YES];
  }
}
