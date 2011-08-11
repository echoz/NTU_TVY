//
//  JONTUBus.h
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
#import "JONTUBusRoute.h"

@interface JONTUBus : NSObject <NSCoding> {
	NSUInteger busid;
	JONTUBusRoute *route;
	NSString *busPlate;
	NSNumber *lat;
	NSNumber *lon;
	NSUInteger speed;
	BOOL hide;
	NSNumber *iscdistance;
}

-(id)initWithID:(NSUInteger)busID route:(JONTUBusRoute *)busRoute plateNumber:(NSString *)busPlate longtitude:(NSNumber *)busLong latitude:(NSNumber *)busLat speed:(NSUInteger)busSpeed hide:(BOOL)busHide iscDistance:(NSNumber *)iscdist;
@property (nonatomic, retain) NSNumber *lat;
@property (nonatomic, retain) NSNumber *lon;
@property (nonatomic, readwrite) NSUInteger speed;

@property (readonly) NSUInteger busid;
@property (readonly) JONTUBusRoute *route;
@property (readonly) NSString *busPlate;
@property (readonly) BOOL hide;
@property (readonly) NSNumber *iscdistance;

@end
