#import <Cocoa/Cocoa.h>
#import "DownloadOperation.h"

@interface MainController : NSWindowController <DownloadOperationDelegate> {
    IBOutlet NSImageView *imageView;
    NSMutableSet *imageURLs;
    NSImage *posterImage;
    NSError *error;
    NSString *searchString;
    NSOperationQueue *operationQueue;
    CGFloat percentageComplete;
}

@property (readonly, retain) NSImage *posterImage;
@property (readwrite, copy) NSString *searchString;
@property (readonly, assign) CGFloat percentageComplete;

-(IBAction)makePoster:(id)sender;
-(IBAction)savePoster:(id)sender;

@end
