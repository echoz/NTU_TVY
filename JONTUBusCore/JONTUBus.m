//
//  JONTUBus.m
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

#import "JONTUBus.h"


@implementation JONTUBus
@synthesize speed, lon, lat;
@synthesize busid, route, busPlate, hide, iscdistance;

-(id)initWithID:(NSUInteger)bID route:(JONTUBusRoute *)busRoute plateNumber:(NSString *)plateNumber longtitude:(NSNumber *)busLong latitude:(NSNumber *)busLat speed:(NSUInteger)busSpeed hide:(BOOL)busHide iscDistance:(NSNumber *)iscdist {
	if (self = [super init]) {
		busid = bID;
		route = [busRoute retain];
		busPlate = [plateNumber copy];
		lon = [busLong copy];
		lat = [busLat copy];
		speed = busSpeed;
		hide = busHide;
		iscdistance = [iscdist copy];
	}
	return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		busid = [aDecoder decodeIntegerForKey:@"busid"];
		route = [[aDecoder decodeObjectForKey:@"route"] retain];
		busPlate = [[aDecoder decodeObjectForKey:@"busPlate"] retain];
		lon = [[aDecoder decodeObjectForKey:@"lon"] retain];
		lat = [[aDecoder decodeObjectForKey:@"lat"] retain];
		speed = [aDecoder decodeIntegerForKey:@"speed"];
		hide = [aDecoder decodeBoolForKey:@"hide"];
		iscdistance = [[aDecoder decodeObjectForKey:@"iscdistance"] retain];		
	}
	return self;
	
}

-(void)encodeWithCoder:(NSCoder *)aCoder {	
	NSLog(@"Encoding bus object: %@", busPlate);
	[aCoder encodeInteger:busid forKey:@"busid"];
	[aCoder encodeObject:route forKey:@"route"];
	[aCoder encodeObject:busPlate forKey:@"busPlate"];
	[aCoder encodeObject:lat forKey:@"lat"];
	[aCoder encodeObject:lon forKey:@"lon"];
	[aCoder encodeInteger:speed forKey:@"speed"];
	[aCoder encodeBool:hide forKey:@"hide"];
	[aCoder encodeObject:iscdistance forKey:@"iscdistance"];
}

-(void)dealloc {
	[lon release];
	[lat release];
	[route release];
	[busPlate release];
	[iscdistance release];
	[super dealloc];
}

@end
