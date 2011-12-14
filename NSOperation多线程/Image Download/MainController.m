#import "MainController.h"

@interface MainController ()
@property (readwrite, retain) NSOperationQueue *operationQueue;
@end


@interface MainController (Private)
-(void)downloadImageURLs;
-(void)startOperations;
-(void)handleError;
@end


@implementation MainController

static const NSUInteger NUMBER_OF_IMAGES = 200;

@synthesize searchString;
@synthesize percentageComplete;
@synthesize operationQueue;

+(NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    NSMutableSet *keyPaths = [[super keyPathsForValuesAffectingValueForKey:key] mutableCopy];
    if ( [key isEqualToString:@"percentageComplete"] ) {
        [keyPaths addObject:@"operationQueue.operations"];
    }
    return keyPaths;
}

-(CGFloat)percentageComplete {
    NSUInteger numberLeft = operationQueue.operations.count;
    return 100.0 * (NUMBER_OF_IMAGES - numberLeft) / (CGFloat)NUMBER_OF_IMAGES;
}

//button触发的方法
-(IBAction)downloadImages:(id)sender {
    
    imageURLs = [[NSMutableSet alloc] init];
    [self startOperations];
}

-(void)startOperations {      
    // Setup the operation queue.
    // Cancel any previous operations that might be running
    [operationQueue cancelAllOperations];  
    self.operationQueue = [[NSOperationQueue alloc] init];
    [operationQueue setMaxConcurrentOperationCount:8];
    
    // Download URLs from Yahoo!
    [self downloadImageURLs];
    
    // Create download folder
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES);
    NSString *downloadFolder = [[searchPaths lastObject] stringByAppendingPathComponent:@"Image Download"];
    if ( ![[NSFileManager defaultManager] fileExistsAtPath:downloadFolder] ) {
        [[NSFileManager defaultManager] createDirectoryAtPath:downloadFolder attributes:nil];
    }
    
    // Create the image download operations, and add them to the queue
    NSUInteger count = 0;
    for ( NSURL *url in imageURLs ) {
        NSString *extension = [[url path] pathExtension];
        NSString *filename = [NSString stringWithFormat:@"Image %d.%@", ++count, extension];
        
        // Image 1.jpg
        NSString *downloadPath = [downloadFolder stringByAppendingPathComponent:filename];
        DownloadOperation *operation = [[DownloadOperation alloc] initWithURL:url downloadPath:downloadPath];
        [operationQueue addOperation:operation];
    }
}


//下载图片url地址
-(void)downloadImageURLs {
    if ( nil == searchString ) {
        [self handleError];
        return;
    }
    
    // Retrieve the XML from the Yahoo! web service, 50 at a time
    NSUInteger count = 0, downloadCount = 0; 
    while ( count < NUMBER_OF_IMAGES ) {
        NSString *queryString = [searchString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *indexURLString = [NSString stringWithFormat:
            @"http://search.yahooapis.com/ImageSearchService/V1/imageSearch?query=%@&results=%d&start=%d&appid=DhCWzTzV34EnBBY5jMbTxGXKk0qVQWPX_JV35cRoqXsDCs2OUrKeRlEH47vfcQJMx6ZRTQ--", queryString, 50, 50*downloadCount+1];
        
//        NSLog(@"indexURLStr = %@",indexURLString);
        
        NSURL *indexURL = [NSURL URLWithString:indexURLString];
        NSXMLDocument *document = [[NSXMLDocument alloc] initWithContentsOfURL:indexURL options:0 error:&error];
        if ( nil == document ) {
            [self handleError];
            return;
        }
        
        // Use Xpath to extract url nodes from XML document
        NSArray *nodes = [document nodesForXPath:@"./ResultSet/Result/Url" error:&error];
        if ( nil != error ) {
            [self handleError];
            return;
        }
        
        // Extract URLs from the XML nodes
        for ( NSXMLElement *element in nodes ) {
            NSString *urlString = [[element childAtIndex:0] stringValue];
            NSURL *url = [NSURL URLWithString:urlString];
            if ( count++ < NUMBER_OF_IMAGES ) [imageURLs addObject:url];
        }
        downloadCount++;
    }
}

-(void)handleError {
    [operationQueue cancelAllOperations];
    if ( error ) 
//        弹框
        [[NSApplication sharedApplication] performSelectorOnMainThread:@selector(presentError:) withObject:error waitUntilDone:NO];
    
    NSLog(@"error = %@",error);
    error = nil;
}

@end
