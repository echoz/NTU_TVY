//
//  JOIris.m
//  NTUBusArrival
//
//  Created by Jeremy Foo on 3/24/10.
//
//  The MIT License
//  
//  Copyright (c) 2010 Jeremy Foo
//  
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
#import "JOIris.h"
#import "RegexKitLite.h"

#define IRISURL @"http://www.sbstransit.com.sg/mobileiris/"
#define IRISSTOP @"index_nextbus.aspx"
#define IRISARRIVAL @"index_mobresult.aspx?stop=%@&svc=%@"
#define IRISSTOPREFERER @"mobresult_stopsearch.aspx"
#define IRISSEARCH @"mobresult_stopsearch.aspx?roaddesc=%@"
#define IRISSTOPS @"mobresult_stoplist.aspx?roadcode=%@"

#define REGEX_UFPS @"action=\"index.aspx\\?__ufps=([0-9a-zA-Z]*)\""
#define REGEX_STOPDETAILS @"<font size=\"-1\">(.*)<br>\\s*(.*)</font><br>"
#define REGEX_BUSES @"<a href=\"index_mobresult.aspx?[^\"]*\">(.*)</a>"
#define REGEX_BUS @"Service (.*)[\\n\\r\\t]*Next bus: (.*)[\\n\\r\\t]*Subsequent bus: (.*)"
#define REGEX_ROADCODES @"<a href=\"mobresult_stoplist.aspx\\?roadcode=([a-zA-Z0-9]*)\">(.*)</a>"
#define REGEX_STOPS @"<a href=\"mobresult_svclist.aspx\\?stopcode=([0-9a-zA-Z]*)\">([0-9A-Za-z]*) - (.*)</a>"

#define HTTP_USER_AGENT @"Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_3; en-us) AppleWebKit/533.4+ (KHTML, like Gecko) Version/4.0.5 Safari/531.22.7"

@interface JOIris (PrivateMethods)
-(NSString *)escapeString:(NSString *) str;
-(NSData *) sendSyncXHRToURL:(NSURL *)url postValues:(NSDictionary *)postValues referer: (NSString *) referer returningResponse:(NSHTTPURLResponse **) response error:(NSError **)error;
-(NSString *)URLStringWithWebService:(NSString *) webservice;
@end

@implementation JOIris (PrivateMethods)
-(NSString *)escapeString:(NSString *) str {
	return [(NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)str, NULL, CFSTR(" ()<>#%{}|\\^~[]`;/?:@=&$"), kCFStringEncodingUTF8) autorelease];
}

-(NSData *) sendSyncXHRToURL:(NSURL *)url postValues:(NSDictionary *)postValues referer: (NSString *)referer returningResponse:(NSHTTPURLResponse **) response error:(NSError **)error {
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
	[request setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
	
	if (postValues) {
		NSMutableString *post = [NSMutableString string];	
		for (NSString *key in postValues) {
			if ([post length] > 0) {
				[post appendString:@"&"];
			}
			[post appendFormat:@"%@=%@",[self escapeString:key],[self escapeString:[postValues objectForKey:key]]];
		}
		NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
		NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
		[request setValue:postLength forHTTPHeaderField:@"Content-Length"];
		[request setHTTPBody:postData];
		
		[request setHTTPMethod:@"POST"];
		[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
		
	}
	
	[request setValue:HTTP_USER_AGENT forHTTPHeaderField:@"User-Agent"];
	[request setTimeoutInterval:timeout];

	if (referer) {
		[request setValue:referer forHTTPHeaderField:@"Referer"];
	}
	
	if (cookies) {
		[request setAllHTTPHeaderFields:[NSHTTPCookie requestHeaderFieldsWithCookies:cookies]];
	}
	
	NSData *recvData = [NSURLConnection sendSynchronousRequest:request returningResponse:response error:error];
	
	if (!cookies) {
		cookies = [[NSHTTPCookie cookiesWithResponseHeaderFields:[*response allHeaderFields] forURL:[request URL]] retain];
	}

	
	[request release];
	return recvData;
	
}

-(NSString *)URLStringWithWebService:(NSString *) webservice {
	if (hash) {
		if ([webservice hasPrefix:@"/"]) {
		 webservice = [webservice substringToIndex:[webservice length]-1];
		}
		return [NSString stringWithFormat:@"%@%@/%@", IRISURL, hash, webservice];		
	} else {
		return nil;
	}
}
@end



@implementation JOIris
-(id)init {
	return [self initWithTimeout:30];
}

-(id)initWithTimeout:(NSTimeInterval) tout {
	if (self = [super init]) {
		hash = nil;
		cookies = nil;
		timeout = tout;
	}
	return self;
}

-(void) serviceHash {
	NSHTTPURLResponse *resp;
	NSError *err;
	NSArray *path = nil;
	
	NSData *indexPage = [self sendSyncXHRToURL:[NSURL URLWithString:IRISURL] postValues:nil referer:nil returningResponse:&resp error:&err];
	
	if (indexPage) {
		path = [[resp URL] pathComponents];
		
	}
	
	if ([path count] > 0) {
		if ([[[path lastObject] uppercaseString] hasPrefix:@"INDEX"]) {
			hash = [[path objectAtIndex:([path count]-2)] retain];
		} else {
			hash = [[path lastObject] retain];
		}
	}

}

-(NSArray *)arrivalsForService:(NSString *)serviceNumber atBusStop:(NSString *)buscode {
		
	NSArray *busnumber = [serviceNumber captureComponentsMatchedByRegex:@"([0-9]*)([A-Za-z]?)"];
	NSMutableArray *returnArr = nil;

	if ([busnumber count] == 3) {
		if ([[busnumber objectAtIndex:1] length] < 3) {
			serviceNumber = [NSString stringWithFormat:@"%03d%@", [[busnumber objectAtIndex:1] intValue], [busnumber objectAtIndex:2]];
		}
		
		if (!hash) {
			[self serviceHash];
		}
		
		NSString *webservice = [NSString stringWithFormat:IRISARRIVAL, buscode, serviceNumber];
		NSData *returnStr = [self sendSyncXHRToURL:[NSURL URLWithString:[self URLStringWithWebService:webservice]]
										postValues:nil 
										   referer:nil
								 returningResponse:nil 
											 error:nil];
		
		NSString *arrivalData = [[NSString alloc] initWithData:returnStr encoding:NSUTF8StringEncoding];
		
		NSArray *captureData = [[arrivalData stringByReplacingOccurrencesOfRegex:@"<font size=\"-1\">|</font>|<br>" withString:@""] arrayOfCaptureComponentsMatchedByRegex:REGEX_BUS];
		[arrivalData release];
		
		
		if ([captureData count] > 0) {
			NSDictionary *busTiming;
			returnArr = [NSMutableArray arrayWithCapacity:[captureData count]];
			NSString *service = nil;
			
			for (NSArray *bus in captureData) {
				service = [[[bus objectAtIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] stringByReplacingOccurrencesOfRegex:@"^0*" withString:@""];
				
				busTiming = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:service, [[bus objectAtIndex:2] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]], [[bus objectAtIndex:3] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]], nil]
														forKeys:[NSArray arrayWithObjects:@"service",@"eta", @"subsequent", nil]];
				[returnArr addObject:busTiming];
				busTiming = nil;
			}
			
		}
	}
	
	return returnArr;
}

-(NSArray *)roadCodesBySearchingName:(NSString *)search {
	if (!hash) {
		[self serviceHash];
	}
	NSString *webservice = [NSString stringWithFormat:IRISSEARCH,search];	
	NSData *returnStr = [self sendSyncXHRToURL:[NSURL URLWithString:[self URLStringWithWebService:webservice]]
									postValues:nil 
									   referer:nil
							 returningResponse:nil 
										 error:nil];
	NSString *arrivalData = [[NSString alloc] initWithData:returnStr encoding:NSUTF8StringEncoding];
	
	NSArray *roadcodes = [arrivalData arrayOfCaptureComponentsMatchedByRegex:REGEX_ROADCODES];
	[arrivalData release];
	
	NSMutableArray *returnval = nil;
	
	if ([roadcodes count] > 0) {
		NSDictionary *roadcodepair;
		returnval = [NSMutableArray arrayWithCapacity:[roadcodes count]];

		for (NSArray *roadcode in roadcodes) {
			roadcodepair = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[roadcode objectAtIndex:1], [roadcode objectAtIndex:2], nil]
													   forKeys:[NSArray arrayWithObjects:@"code",@"road",nil]];
			[returnval addObject:roadcodepair];
			roadcodepair = nil;
		}
	}	
	
	return returnval;
}

-(NSArray *)stopsAlongRoadCode:(NSString *)roadcode {
	if (!hash) {
		[self serviceHash];
	}
	NSString *webservice = [NSString stringWithFormat:IRISSTOPS, roadcode];	
	NSData *returnStr = [self sendSyncXHRToURL:[NSURL URLWithString:[self URLStringWithWebService:webservice]]
									postValues:nil 
									   referer:nil
							 returningResponse:nil 
										 error:nil];
	NSString *arrivalData = [[NSString alloc] initWithData:returnStr encoding:NSUTF8StringEncoding];
	
	NSArray *stops = [arrivalData arrayOfCaptureComponentsMatchedByRegex:REGEX_STOPS];
	[arrivalData release];
	
	NSMutableArray *returnval = nil;
	
	if ([stops count] > 0) {
		NSDictionary *stopcodepair;
		returnval = [NSMutableArray arrayWithCapacity:[stops count]];
		
		for (NSArray *stop in stops) {
			stopcodepair = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[stop objectAtIndex:1], [stop objectAtIndex:3], nil]
													   forKeys:[NSArray arrayWithObjects:@"code",@"stop",nil]];
			[returnval addObject:stopcodepair];
			stopcodepair = nil;
		}
	}	
	
	return returnval;
	
}

-(NSDictionary *)busesAtBusStop:(NSString *)buscode {
	if (!hash) {
		[self serviceHash];
	}

	NSMutableDictionary *postvalues = [NSMutableDictionary dictionary];
	[postvalues setObject:@"" forKey:@"__EVENTTARGET"];
	[postvalues setObject:@"" forKey:@"__EVENTARGUMENT"];
	[postvalues setObject:buscode forKey:@"txtbusstop"];
	[postvalues setObject:@"" forKey:@"txtsvcno"];
	[postvalues setObject:@"submit" forKey:@"btngo"];
	
	
	NSData *returnStr = [self sendSyncXHRToURL:[NSURL URLWithString:[self URLStringWithWebService:IRISSTOP]]
									postValues:postvalues 									   
									   referer:nil
							 returningResponse:nil 
										 error:nil];
	
	NSString *stop = [[NSString alloc] initWithData:returnStr encoding:NSUTF8StringEncoding];
	
	NSArray *stopdetails = [stop captureComponentsMatchedByRegex:REGEX_STOPDETAILS];
	NSArray *buses = [stop arrayOfCaptureComponentsMatchedByRegex:REGEX_BUSES];
	[stop release];

	NSMutableDictionary *dict = nil;
	
	if ([stopdetails count] > 0) {
		
		dict = [NSMutableDictionary dictionary];
		[dict setObject:[stopdetails objectAtIndex:1] forKey:@"stop"];
		[dict setObject:[stopdetails objectAtIndex:2] forKey:@"location"];
		
		NSMutableArray *busnumbers = [NSMutableArray arrayWithCapacity:[buses count]];
		
		for (NSArray *bus in buses) {
			[busnumbers addObject:[bus objectAtIndex:1]];
		}
		
		[dict setObject:busnumbers forKey:@"buses"];
		
	}
	
	return dict;
}

-(void)dealloc {
	[hash release], hash = nil;
	[cookies release], cookies = nil;
	[super dealloc];
}


	
@end
