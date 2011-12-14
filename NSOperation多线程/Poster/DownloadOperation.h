
#import <Cocoa/Cocoa.h>

@class DownloadOperation;
//      url + image 

@protocol DownloadOperationDelegate 
-(NSURL *)urlForDownloadOperation:(DownloadOperation *)operation;
-(void)processImageForDownloadOperation:(DownloadOperation *)operation;
@end

@interface DownloadOperation : NSOperation {
    NSObject <DownloadOperationDelegate> *delegate;
    NSImage *downloadedImage;
    NSInteger zIndex;
}

@property (readwrite, assign) NSObject <DownloadOperationDelegate> *delegate;
@property (readonly, retain) NSImage *downloadedImage;
@property (readwrite, assign) NSInteger zIndex;

@end
