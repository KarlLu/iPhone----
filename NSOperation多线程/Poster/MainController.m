#import "MainController.h"

// NSImage category useful for resizing images
@interface NSImage (Resizing)

-(NSSize)sizeToFitMaximumSizeConstraint:(NSSize)maxSize;

@end

@implementation NSImage (Resizing)

-(NSSize)sizeToFitMaximumSizeConstraint:(NSSize)maxSize {
    CGFloat widthRatio = 1.0f;
    CGFloat heightRatio = 1.0f;
    if ( [self size].width != 0.0f && [self size].height != 0.0f ) {
        widthRatio = maxSize.width / [self size].width;
        heightRatio = maxSize.height / [self size].height;
    }
    CGFloat scaleFactor = MIN( MIN(1.0f, widthRatio), heightRatio);
    CGFloat width = [self size].width * scaleFactor;
    CGFloat height = [self size].height * scaleFactor;   
    return NSMakeSize(width, height);
}

@end


// Constants
static const NSUInteger NUMBER_OF_IMAGES = 200;
static const NSUInteger NUMBER_OF_LAYERS = 5;
static const CGFloat POSTER_HEIGHT = 900.0;
static const CGFloat POSTER_WIDTH = 1440.0;


// Private methods
@interface MainController ()
@property (readwrite, retain) NSImage *posterImage;
@property (readwrite, assign) CGFloat percentageComplete;
@end

@interface MainController (Private)
-(void)downloadImageURLs;
-(void)startOperations;
-(void)refreshPosterImage;
-(void)handleError;
@end


@implementation MainController

@synthesize searchString;
@synthesize percentageComplete;
@synthesize posterImage;

#pragma mark Action Methods
-(IBAction)makePoster:(id)sender {
    self.percentageComplete = 0.0f;
    imageURLs = [[NSMutableSet alloc] init];
    
    // Create white canvas to make poster on
    self.posterImage = [[NSImage alloc] initWithSize:NSMakeSize(POSTER_WIDTH, POSTER_HEIGHT)];
    [self.posterImage lockFocus];
    NSRect posterRect = NSZeroRect;
    posterRect.size = [self.posterImage size];
    [[NSColor whiteColor] set];
    [NSBezierPath fillRect:posterRect];
    [self.posterImage unlockFocus];
    
    [self startOperations];
}

-(IBAction)savePoster:(id)sender {
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setDelegate:self];
    [savePanel setCanCreateDirectories:YES];
    [savePanel setPrompt:@"Save"];
    [savePanel setTitle:@"Save Poster"];
    [savePanel setAllowedFileTypes:[NSArray arrayWithObject:@"tiff"]];
    [savePanel beginSheetForDirectory:nil file:@"Untitled" modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(posterSavePanelDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

-(void)posterSavePanelDidEnd:(NSSavePanel *)panel returnCode:(int)returnCode contextInfo:(void  *)contextInfo {
    if ( returnCode == NSOKButton ) {
        [[posterImage TIFFRepresentation] writeToFile:[panel filename] atomically:YES];
    }
}


#pragma mark Operation Methods
-(void)startOperations {      
    // Setup the operation queue.
    // Cancel any previous operations that might be running
    [operationQueue cancelAllOperations];  
    operationQueue = [[NSOperationQueue alloc] init];
    [operationQueue setSuspended:YES];    // Suspend until all dependencies are setup
    
    // Add the index downloading operation
    NSInvocationOperation *indexOperation = [[NSInvocationOperation alloc] initWithTarget:self  
        selector:@selector(downloadImageURLs) object:nil];
    [operationQueue addOperation:indexOperation];
    
    // Loop over layers (z-index) from back to front, creating operations to download images.
    // Images for each layer are dependent on those in the previous layer.
    NSInteger zIndex;
    NSInvocationOperation *lastLayerOperation = nil;
    for ( zIndex = 0; zIndex < NUMBER_OF_LAYERS; zIndex++ ) {
        
        // Create one operation for each layer, to refresh interface, and to make setting up
        // dependencies a bit easier.
        NSInvocationOperation *layerOperation = 
            [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(refreshPosterImage) object:nil];
        [operationQueue addOperation:layerOperation];
        
        // Setup download operations for images in this layer
        NSInteger imageIndex;
        for ( imageIndex = 0; imageIndex < NUMBER_OF_IMAGES / NUMBER_OF_LAYERS; ++imageIndex ) {
            DownloadOperation *operation = [[DownloadOperation alloc] init];
            operation.zIndex = zIndex;
            operation.delegate = self;
            if ( nil != lastLayerOperation ) {
                [operation addDependency:lastLayerOperation];  // This operation depends on last layer
            }
            else {
                [operation addDependency:indexOperation];      // First layer downloads depend on URLs download
            }
            [layerOperation addDependency:operation];          // Next layer depends on this operation
            [operationQueue addOperation:operation];       
        }
        
        // Update last layer
        lastLayerOperation = layerOperation;
    }
    
    // Start the operation queue running
    [operationQueue setSuspended:NO];
}

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
        
        NSLog(@"==indexURLString = %@",indexURLString);
        
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

#pragma mark Interface Methods
-(void)refreshPosterImage {
    // Force image update in interface
    [self performSelectorOnMainThread:@selector(refreshPosterImageOnMainThread) withObject:nil waitUntilDone:NO];
}

-(void)refreshPosterImageOnMainThread {
    [imageView setNeedsDisplay:YES];
}

-(void)handleError {
    [operationQueue cancelAllOperations];
    if ( error ) [[NSApplication sharedApplication] performSelectorOnMainThread:@selector(presentError:) withObject:error waitUntilDone:NO];
    error = nil;
}

#pragma mark DownloadOperation Delegate Methods
-(NSURL *)urlForDownloadOperation:(DownloadOperation *)operation; {
    NSURL *url;
    @synchronized (imageURLs) {
        url = [imageURLs anyObject];
        [imageURLs removeObject:url];
    }
    return url;
}

-(void)processImageForDownloadOperation:(DownloadOperation *)operation {
    if ( [operation isCancelled] ) return;
    
    [posterImage lockFocus];
    
    // Determine size of image in poster, and take account of z-index
    CGFloat zIndexFactor = 0.6f + operation.zIndex * 0.1f;
    NSSize maxSize = NSMakeSize(POSTER_WIDTH * 0.15f * zIndexFactor, POSTER_HEIGHT * 0.15f * zIndexFactor);
    NSSize scaledSize = [operation.downloadedImage sizeToFitMaximumSizeConstraint:maxSize];
    
    // Draw at random point in poster
    CGFloat originX = (-0.05f + rand() / (CGFloat)RAND_MAX ) * POSTER_WIDTH;
    CGFloat originY = (-0.05f + rand() / (CGFloat)RAND_MAX ) * POSTER_HEIGHT;
    NSRect imageInPosterRect, imageRect = NSZeroRect;
    imageInPosterRect.origin = NSMakePoint(originX, originY);
    imageInPosterRect.size = scaledSize;
    imageRect.size = [operation.downloadedImage size];
    [operation.downloadedImage drawInRect:imageInPosterRect fromRect:imageRect operation:NSCompositeCopy fraction:1.0f];
    
    [posterImage unlockFocus];
        
    self.percentageComplete += 100.0f / NUMBER_OF_IMAGES;
}

@end
