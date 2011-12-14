
#import "DownloadOperation.h"

@interface DownloadOperation ()
@property (readwrite, copy) NSURL *url;
@property (readwrite, copy) NSString *downloadPath;
@end

@implementation DownloadOperation

@synthesize url;
@synthesize downloadPath;

-(id)initWithURL:(NSURL *)newURL downloadPath:(NSString *)newDownloadPath {
    if ( self = [super init] ) {
        self.url = newURL;
        self.downloadPath = newDownloadPath;
    }
    return self;
}

-(void)main {
    
    if ( self.isCancelled ) return;
    if ( nil == self.url ) return;
    NSData *imageData = [NSData dataWithContentsOfURL:self.url]; 
    if ( self.isCancelled ) return;
    [imageData writeToFile:self.downloadPath atomically:NO];
    
    
//  后台数据是json格式，配合NSOperation使用
/*
    1.同步调用NSURLConnection获取NSData数据
    2.[self parseDataToStandardData:originalData];
    3.delegate方法中调用将standardData转换成UI对应的数据项。
*/
  

}

@end
