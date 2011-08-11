//
//  JONTUBusEngine.h
//  NTUBusArrival
//
//  Created by Jeremy Foo on 3/26/10.
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

#import <Foundation/Foundation.h>
#import "SynthesizeSingleton.h"
#import "JONTUBus.h"
#import "JONTUBusStop.h"
#import "JONTUBusRoute.h"

@interface JONTUBusEngine : NSObject <NSXMLParserDelegate, NSCoding> {
	NSArray *buses;
	NSArray *routes;
	NSArray *stops;
	NSData *indexPageCache;
	NSDate *lastGetIndexPage;
	BOOL dirty;
	BOOL brandNew;
	int holdCache;
	
	NSMutableArray *tempbuses;
}

@property (readonly) BOOL dirty;
@property (readonly) BOOL brandNew;
@property (readwrite) int holdCache;
@property (readonly) NSDate *lastGetIndexPage;
@property (readonly) NSData *indexPageCache;

SYNTHESIZE_SINGLETON_FOR_CLASS_HEADER(JONTUBusEngine);

-(void) start;
-(NSArray *)routes;
-(NSArray *)routesWithRefresh:(BOOL)refresh;
-(JONTUBusRoute *)routeForName:(NSString *)routename;
-(JONTUBusRoute *)routeForId:(NSUInteger)routeid;

-(NSArray *)stops;
-(NSArray *)stopsWithRefresh:(BOOL)refresh;
-(JONTUBusStop *)stopForId:(NSUInteger)stopid;
-(JONTUBusStop *)stopForCode:(NSString *)code;

-(NSArray *)buses;
-(NSArray *)busesWithRefresh:(BOOL)refresh;
-(JONTUBus *)busForPlate:(NSString *)plate;

/* generic methods */
+(JONTUBusEngine *)sharedJONTUBusEngine;
+(void)loadState:(NSString *)archiveFilePath;
+(void)saveState:(NSString *)archiveFilePath;
-(NSData *)sendXHRToURL:(NSString *)url PostValues:(NSDictionary *)postValues;
-(NSData *)getIndexPage;

@end
