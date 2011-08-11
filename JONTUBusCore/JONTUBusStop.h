//
//  JONTUBusStop.h
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

#import <Foundation/Foundation.h>

@interface JONTUBusStop : NSObject <NSXMLParserDelegate, NSCoding> {
	NSUInteger busstopid;
	NSString *code;
	NSString *desc;
	NSString *roadName;
	NSNumber *lon;
	NSNumber *lat;
	NSArray *otherBus;
	NSArray *routes;
	
	// praser setuff
	NSString *currentRouteid;
	NSString *currentRouteName;
	NSMutableArray *arrivals;
}

-(id)initWithID:(NSUInteger)stopID code:(NSString *)stopCode description:(NSString *)stopDesc roadName:(NSString *)stopRdName longtitude:(NSNumber *)stopLong latitude:(NSNumber *)stopLat otherBuses:(NSArray *)stopOtherBus;
-(NSArray *) arrivals;

@property (nonatomic, retain) NSArray *routes;

@property (readonly) NSArray *otherBus;
@property (readonly) NSUInteger busstopid;
@property (readonly) NSString *code;
@property (readonly) NSString *desc;
@property (readonly) NSString *roadName;
@property (readonly) NSNumber *lon;
@property (readonly) NSNumber *lat;

@end
