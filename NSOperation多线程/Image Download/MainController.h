#import <Cocoa/Cocoa.h>
#import "DownloadOperation.h"

@interface MainController : NSWindowController {
    NSMutableSet *imageURLs;
    NSError *error;
    NSString *searchString;
    NSOperationQueue *operationQueue;
    CGFloat percentageComplete;
}

@property (readwrite, copy) NSString *searchString;
@property (readonly, assign) CGFloat percentageComplete;

-(IBAction)downloadImages:(id)sender;

@end
