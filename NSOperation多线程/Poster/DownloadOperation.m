
#import "DownloadOperation.h"

@interface DownloadOperation ()
@property (readwrite, retain) NSImage *downloadedImage;
@end

@implementation DownloadOperation

@synthesize delegate;
@synthesize downloadedImage;
@synthesize zIndex;

-(void)main {
    if ( self.isCancelled ) return;
    if ( nil != delegate ) {
        NSURL *url = [delegate urlForDownloadOperation:self];
        if ( nil == url ) return;
        self.downloadedImage = [[NSImage alloc] initWithContentsOfURL:url];
        if ( self.isCancelled ) return;
        [delegate performSelectorOnMainThread:@selector(processImageForDownloadOperation:) withObject:self waitUntilDone:YES];
    }
}

@end
