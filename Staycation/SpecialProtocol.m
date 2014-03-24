/*
     File: SpecialProtocol.m 
 Abstract: Our custom NSURLProtocol. 
  Version: 1.1 
  
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple 
 Inc. ("Apple") in consideration of your agreement to the following 
 terms, and your use, installation, modification or redistribution of 
 this Apple software constitutes acceptance of these terms.  If you do 
 not agree with these terms, please do not use, install, modify or 
 redistribute this Apple software. 
  
 In consideration of your agreement to abide by the following terms, and 
 subject to these terms, Apple grants you a personal, non-exclusive 
 license, under Apple's copyrights in this original Apple software (the 
 "Apple Software"), to use, reproduce, modify and redistribute the Apple 
 Software, with or without modifications, in source and/or binary forms; 
 provided that if you redistribute the Apple Software in its entirety and 
 without modifications, you must retain this notice and the following 
 text and disclaimers in all such redistributions of the Apple Software. 
 Neither the name, trademarks, service marks or logos of Apple Inc. may 
 be used to endorse or promote products derived from the Apple Software 
 without specific prior written permission from Apple.  Except as 
 expressly stated in this notice, no other rights or licenses, express or 
 implied, are granted by Apple herein, including but not limited to any 
 patent rights that may be infringed by your derivative works or by other 
 works in which the Apple Software may be incorporated. 
  
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE 
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION 
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS 
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND 
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS. 
  
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL 
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, 
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED 
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), 
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE 
 POSSIBILITY OF SUCH DAMAGE. 
  
 Copyright (C) 2011 Apple Inc. All Rights Reserved. 
  
 */

#import <Foundation/NSError.h>

#import "SpecialProtocol.h"

#import "NSData+STYAdditions.h"

@implementation SpecialProtocol

	/* class method for protocol called by webview to determine if this
	protocol should be used to load the request. */
+ (BOOL)canInitWithRequest:(NSURLRequest *)theRequest {

	NSLog(@"%@ received %@ with url='%@' and scheme='%@'", 
			self, NSStringFromSelector(_cmd),
			[[theRequest URL] absoluteString], [[theRequest URL] scheme]);
	
		/* get the scheme from the URL */
	NSString *theScheme = [[theRequest URL] scheme];
	
		/* return true if it matches the scheme we're using for our protocol. */
	return [theScheme isEqualToString:@"http"];
}


	/* if canInitWithRequest returns true, then webKit will call your
	canonicalRequestForRequest method so you have an opportunity to modify
	the NSURLRequest before processing the request */
+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {

	NSLog(@"%@ received %@", self, NSStringFromSelector(_cmd));
	
	/* we don't do any special processing here, though we include this
	method because all subclasses must implement this method. */
	
    return request;
}

- (NSString*) mimeTypeForFileAtPath: (NSString *) path {
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return nil;
    }
    // Borrowed from http://stackoverflow.com/questions/5996797/determine-mime-type-of-nsdata-loaded-from-a-file
    // itself, derived from  http://stackoverflow.com/questions/2439020/wheres-the-iphone-mime-type-database
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef)CFBridgingRetain([path pathExtension]), NULL);
    CFStringRef mimeType = UTTypeCopyPreferredTagWithClass (UTI, kUTTagClassMIMEType);
    CFRelease(UTI);
    if (!mimeType) {
        return @"application/octet-stream";
    }
    return (NSString *)CFBridgingRelease(mimeType);
}

#define SET_ENVIRONMENT(key, value) [environment setValue:(value) forKey:(key)];

	/* our main loading routine.  This is where we do most of our processing
	for our class.  In this case, all we are doing is taking the path part
	of the url and rendering it in 36 point system font as a jpeg file.  The
	interesting part is that we create the jpeg entirely in memory and return
	it back for rendering in the webView.  */
- (void)startLoading {
	NSLog(@"%@ received %@ - start", self, NSStringFromSelector(_cmd));
	
		/* retrieve the current request. */
    NSURLRequest *request = [self request];
    
	
		/* Since the scheme is free to encode the url in any way it chooses, here
		we are using the url text to identify files names in our resources folder
		that we would like to display. */
		
		/* allocate an NSImage with large dimensions enough to draw the entire string. */
    
    NSString *baseString = [[NSString alloc] initWithData:[NSData STYAdditions_dataWithHexEncodedString:[request.URL host]] encoding:NSUTF8StringEncoding];
    NSString *pathString = [request.URL path];
    
    NSString *file = [baseString stringByAppendingPathComponent:pathString];
    
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:file error:NULL];
    
    if ([fileAttributes[NSFileType] isEqual:NSFileTypeDirectory])
    {
        NSFileManager *defaultManager = [NSFileManager defaultManager];
        NSSet *fileContents = [NSSet setWithArray:[defaultManager contentsOfDirectoryAtPath:file error:NULL]];
        
        NSArray *possibleFiles = @[
                                   @"index.html",
                                   @"index.cgi"
                                   ];
        
        for (NSString *possibleFile in possibleFiles)
        {
            if ([fileContents containsObject:possibleFile])
            {
                file = [file stringByAppendingPathComponent:possibleFile];
                break;
            }
        }
    }
    
    fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:file error:NULL];
    
    if ([fileAttributes[NSFilePosixPermissions] integerValue] & 0x40)
    {
        NSTask * task = [[NSTask alloc] init];
        [task setLaunchPath:file];
        [task setCurrentDirectoryPath:[file stringByDeletingLastPathComponent]];
        
        NSMutableDictionary *environment = [NSMutableDictionary dictionary];
        
        SET_ENVIRONMENT(@"CONTENT_LENGTH", ([NSString stringWithFormat:@"%ld", [request.HTTPBody length]]));
        SET_ENVIRONMENT(@"CONTENT_TYPE", request.allHTTPHeaderFields[@"Content-Type"]);
        SET_ENVIRONMENT(@"DOCUMENT_ROOT", [baseString stringByAppendingString:@"/"]);
        SET_ENVIRONMENT(@"GATEWAY_INTERFACE", @"CGI/1.1");
        
        NSArray *preferredLanguages = [NSLocale preferredLanguages];
        NSMutableString *acceptLangauges = [NSMutableString string];
        double languageIndex = 1;
        for (NSString* languageIdentifier in preferredLanguages)
        {
            NSString* acceptLangauge = [languageIdentifier stringByReplacingOccurrencesOfString:@"_" withString:@"-"];
            acceptLangauge = [acceptLangauge lowercaseString];
            
            double languageQuality = 1. - languageIndex/[preferredLanguages count];
            if (languageIndex > 1)
            {
                [acceptLangauges appendFormat:@", %@;q=%.3f", acceptLangauge, languageQuality];
            }
            else
            {
                [acceptLangauges appendString:acceptLangauge];
            }
            
            languageIndex++;
        }
        SET_ENVIRONMENT(@"HTTP_ACCEPT_LANGUAGE", acceptLangauges);
        SET_ENVIRONMENT(@"HTTP_USER_AGENT", request.allHTTPHeaderFields[@"User-Agent"]);
        SET_ENVIRONMENT(@"HTTP_X_REQUESTED_WITH", request.allHTTPHeaderFields[@"X-Requested-With"]);
        SET_ENVIRONMENT(@"QUERY_STRING", [request.URL query] ?: @"");
        SET_ENVIRONMENT(@"REQUEST_METHOD", request.HTTPMethod);
        SET_ENVIRONMENT(@"REQUEST_URI", pathString);
        SET_ENVIRONMENT(@"SCRIPT_FILENAME", file);
        SET_ENVIRONMENT(@"SCRIPT_NAME", pathString);
        SET_ENVIRONMENT(@"SERVER_ADMIN", @"[no address given]");
        SET_ENVIRONMENT(@"SERVER_PROTOCOL", @"HTTP/1.0");

        //        SET_ENVIRONMENT(@"HTTP_ACCEPT_ENCODING", nil);
        //        SET_ENVIRONMENT(@"HTTP_ACCEPT", nil);
        //        SET_ENVIRONMENT(@"HTTP_CONNECTION", nil);
        //        SET_ENVIRONMENT(@"HTTP_HOST", nil);
        //        SET_ENVIRONMENT(@"HTTP_ORIGIN", nil);
        //        SET_ENVIRONMENT(@"HTTP_REFERER", nil);
        //        SET_ENVIRONMENT(@"PATH", nil);
        //        SET_ENVIRONMENT(@"REMOTE_ADDR", nil);
        //        SET_ENVIRONMENT(@"REMOTE_PORT", nil);
        //        SET_ENVIRONMENT(@"SERVER_ADDR", nil);
        //        SET_ENVIRONMENT(@"SERVER_NAME", nil);
        //        SET_ENVIRONMENT(@"SERVER_PORT", nil);
        //        SET_ENVIRONMENT(@"SERVER_SIGNATURE", nil);
        //        SET_ENVIRONMENT(@"SERVER_SOFTWARE", nil);

        [task setEnvironment:environment];
        
        NSPipe *inPipe = [NSPipe pipe];
        [task setStandardInput:inPipe];

        
        NSPipe * outPipe = [NSPipe pipe];
        [task setStandardOutput:outPipe];
        
        NSPipe * errPipe = [NSPipe pipe];
        [task setStandardError:errPipe];
        
        [task launch];
        
        if (request.HTTPBody)
        {
            [[inPipe fileHandleForWriting] writeData:request.HTTPBody];
            NSLog(@"%@", [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding]);
        }
        [[inPipe fileHandleForWriting] closeFile];
        
        NSMutableDictionary *headerFields = [NSMutableDictionary dictionary];
        NSMutableData *data = [NSMutableData data];
        [data appendData:[[outPipe fileHandleForReading] readDataToEndOfFile]];
        
        if ([data length] > 0)
        {
            NSRange range = [data rangeOfData:[@"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding] options:0 range:NSMakeRange(0, [data length])];
            
            headerFields[@"Content-Type"] = @"text/html";
            
            if (range.location != NSNotFound)
            {
                NSString *headers = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(0, range.location)] encoding:NSUTF8StringEncoding];
                
                NSLog(@"headers: %@", headers);
                
                [headers enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
                    NSArray *entry = [line componentsSeparatedByString:@":"];
                    NSString *key = [entry[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    NSString *value = [entry[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    headerFields[key] = value;
                }];
                [data replaceBytesInRange:NSMakeRange(0, range.location + range.length) withBytes:NULL length:0];
            }
        }
        else
        {
            headerFields[@"Content-Type"] = @"text/plain";
            [data appendData:[[errPipe fileHandleForReading] readDataToEndOfFile]];
        }
        
        NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        [self handleData:data headerFields:headerFields request:request];
    }
    else
    {
        NSData *data = [NSData dataWithContentsOfFile:file];
        NSString *mimeType = [self mimeTypeForFileAtPath:file];
        [self handleData:data headerFields:@{@"Content-Type" : mimeType} request:request];
    }
}

-(void)handleData:(NSData*)data headerFields:(NSDictionary*)headerFields request:(NSURLRequest*)request
{
    /* create the response record, set the mime type to jpeg */
    
    NSMutableDictionary *extendedHeaderFields = [NSMutableDictionary dictionaryWithDictionary:headerFields];
    extendedHeaderFields[@"Access-Control-Allow-Origin"] = @"*";
    extendedHeaderFields[@"Access-Control-Allow-Headers"] = @"Content-Type";
    extendedHeaderFields[@"Content-Length"] = [NSString stringWithFormat:@"%ld", [data length]];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:request.URL
                                                              statusCode:200
                                                             HTTPVersion:@"1.0"
                                                            headerFields:extendedHeaderFields];
    
    /* turn off caching for this response data */
	[[self client] URLProtocol:self didReceiveResponse:response
     cacheStoragePolicy:NSURLCacheStorageNotAllowed];
	
    /* set the data in the response to our jfif data */
	[[self client] URLProtocol:self didLoadData:data];
	
    /* notify that we completed loading */
	[[self client] URLProtocolDidFinishLoading:self];
    
    /* if an error occured during our load, here is the code we would
     execute to send that information back to webKit.  We're not using it here,
     but you will probably want to use this code for proper error handling.  */
	if (0) { /* in case of error */
        int resultCode;
        resultCode = NSURLErrorResourceUnavailable;
        [[self client] URLProtocol:self didFailWithError:[NSError errorWithDomain:NSURLErrorDomain
                                                                      code:resultCode userInfo:nil]];
	}
    
    /* added the extra log statement here so you can see that stopLoading is called
     by the underlying machinery before we leave this routine. */
	NSLog(@"%@ received %@ - end", self, NSStringFromSelector(_cmd));
}

		/* called to stop loading or to abort loading.  We don't do anything special
		here. */
- (void)stopLoading
{
	NSLog(@"%@ received %@", self, NSStringFromSelector(_cmd));
}


@end

