//
//  JONTUBusRoute.m
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

#import "JONTUBusRoute.h"
#import "JONTUBusEngine.h"
#import "JONTUBusStop.h"

@implementation JONTUBusRoute

@synthesize routeid, name, dirty, color, colorAlt, polylines;

static NSString *getRouteBusStops = @"http://campusbus.ntu.edu.sg/ntubus/index.php/main/getCurrentBusStop";

-(id)initWithID:(NSUInteger)rid name:(NSString *)rname color:(NSString*)clr colorAlt:(NSString *)clrAlt stops:(NSArray *)busstops polylines:(NSArray *)plines {
	if (self = [super init]) {
		routeid = rid;
		name = [rname copy];
		stops = [busstops copy];
		color = [clr copy];
		colorAlt = [clrAlt copy];
		tempstops = nil;
		polylines = [plines copy];
	}
	return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		routeid = [aDecoder decodeIntegerForKey:@"routeid"];
		name = [[aDecoder decodeObjectForKey:@"name"] retain];
		stops = [[aDecoder decodeObjectForKey:@"stops"] retain];
		lastGetStops = [[aDecoder decodeObjectForKey:@"lastGetStops"] retain];
		dirty = [aDecoder decodeBoolForKey:@"dirty"];
		color = [[aDecoder decodeObjectForKey:@"color"] retain];
		colorAlt = [[aDecoder decodeObjectForKey:@"colorAlt"] retain];
		polylines = [[aDecoder decodeObjectForKey:@"polylines"] retain];
	}
	return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder {
	NSLog(@"Encoding route object: %@", name);	
	[aCoder encodeInteger:routeid forKey:@"routeid"];
	[aCoder encodeObject:name forKey:@"name"];
	[aCoder encodeObject:stops forKey:@"stops"];
	[aCoder encodeObject:lastGetStops forKey:@"lastGetStops"];
	[aCoder encodeBool:dirty forKey:@"dirty"];
	[aCoder encodeObject:color forKey:@"color"];
	[aCoder encodeObject:colorAlt forKey:@"colorAlt"];
	[aCoder encodeObject:polylines forKey:@"polylines"];
}


-(NSArray *)stops {
	if (dirty) {
		return [self stopsWithRefresh:YES];
	} else {
		return [self stopsWithRefresh:NO];		
	}
}

-(NSArray *)stopsWithRefresh:(BOOL)refresh {
	if (refresh) {
		JONTUBusEngine *engine = [JONTUBusEngine sharedJONTUBusEngine];
		
		NSMutableDictionary *post = [NSMutableDictionary dictionary];
		[post setValue:[NSString stringWithFormat:@"%i",routeid] forKey:@"routeid"];
		[post setValue:[NSString stringWithFormat:@"%f", (float)arc4random()/10000000000] forKey:@"r"];
		
		NSXMLParser *parser = [[NSXMLParser alloc] initWithData:[engine sendXHRToURL:getRouteBusStops PostValues:post]];
		[parser setDelegate:self];
		[parser setShouldProcessNamespaces:NO];
		[parser setShouldReportNamespacePrefixes:NO];
		[parser setShouldResolveExternalEntities:NO];
		
		[parser parse];

		// fuck care error handling for now
		
		[parser release];
		dirty = NO;
	} 
	return stops;
}

- (void)parserDidStartDocument:(NSXMLParser *)parser {
	[tempstops release];
	tempstops = [[NSMutableArray arrayWithCapacity:0] retain];
}

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
	JONTUBusEngine *engine = [JONTUBusEngine sharedJONTUBusEngine];
	JONTUBusStop *stop;

	if ([elementName isEqualToString:@"bus_stop"]) {
		stop = [engine stopForId:[[attributeDict valueForKey:@"id"] intValue]];
		[tempstops addObject:stop];
	}
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
	[stops release];
	stops = [tempstops retain];
	[tempstops release], tempstops = nil;
}

-(void)dealloc {
	[color release];
	[colorAlt release];
	[name release];
	[stops release];
	[polylines release];
	[super dealloc];
}

@end
