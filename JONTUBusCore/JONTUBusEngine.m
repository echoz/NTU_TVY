//
//  JONTUBusEngine.m
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

#import "JONTUBusEngine.h"
#import "RegexKitLite.h"
#import "JOUTM.h"

#define HTTP_USER_AGENT @"Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_3; en-us) AppleWebKit/533.4+ (KHTML, like Gecko) Version/4.0.5 Safari/531.22.7"

@implementation JONTUBusEngine

@synthesize dirty, holdCache, brandNew, lastGetIndexPage, indexPageCache;

static NSString *getBusPosition = @"http://campusbus.ntu.edu.sg/ntubus/index.php/main/getCurrentPosition";
static NSString *indexPage = @"http://campusbus.ntu.edu.sg/ntubus/";

static NSString *regexBusStop = @"ntu.busStop.push\\(\\{\\s*id:(\\d*),\\s*code:(\\d*),\\s*description:\"(.*)\",\\s*roadName:\"(.*)\",\\s*x:([\\d.]*),\\s*y:([\\d.]*),\\s*lon:([\\d.]*),\\s*lat:([\\d.]*),\\s*otherBus:\"(.*)\",\\s*marker:.*,\\s*markerShadow:.*\\s*\\}\\);";
static NSString *regexRoute = @"ntu.routes.push\\(\\{\\s*id:([\\d]*),\\s*name:\"(.*)\",\\s*centerMetric:.*,\\s*centerLonLat:new GeoPoint\\(([\\d.]*), ([\\d.]*)\\),\\s*color:\"#(.*)\",\\s*colorAlt:\"#(.*)\",\\s*zone:(.*),\\s*busStop:.*\\s*\\}\\);";
static NSString *regexRoutePolylines = @"new Vertex\\(([0-9\\.]*),([0-9\\.]*)\\)";

/* better parsing methods
// stop
static NSString *regexStopJSON = @"ntu.busStop.push\\(({(([\\s\\r\\n\\t]*|.*)*)})\\);"; // captures json
static NSString *regexStopContent = @"ntu.busStop.push\\(\\{(([\\s\\r\\n\\t]*|.*)*)}\\);"; // captures content
static NSString *regexStopDetails = @"(.*):\"?([^,\\n\\r\"]*)\"?,?";
// route
static NSString *regexRouteJSON = @"ntu.routes.push\\(({(([\\s\\r\\n\\t]*|.*)*)})\\);";
static NSString *regexRouteContent = @"ntu.routes.push\\(({(([\\s\\r\\n\\t]*|.*)*)})\\);";
static NSString *regexRouteDetails = @"(.*):\"?([^,\\n\\r\"]*)\"?,?"; 
//plus polylines parsing if not using JSON
*/

SYNTHESIZE_SINGLETON_FOR_CLASS(JONTUBusEngine);

+(void)saveState:(NSString *)archiveFilePath {
	@synchronized([JONTUBusEngine class]) {
		JONTUBusEngine *engine = [JONTUBusEngine sharedJONTUBusEngine];
		
		[NSKeyedArchiver archiveRootObject:engine toFile:archiveFilePath];
	}
}

+(void)loadState:(NSString *)archiveFilePath {
	@synchronized([JONTUBusEngine class]) {
		if (!sharedJONTUBusEngine) {
			[JONTUBusEngine sharedJONTUBusEngine];
		}
		
		if ([[NSFileManager defaultManager] fileExistsAtPath:archiveFilePath]) {
			[NSKeyedUnarchiver unarchiveObjectWithFile:archiveFilePath];
		}
	}
}

-(id)init {
	if (self = [super init]) {
		holdCache = 120;
		stops = nil;
		routes = nil;
		buses = nil;
		tempbuses = nil;
		lastGetIndexPage = nil;
		indexPageCache = nil;
		brandNew = YES;
	}
	return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"JONTUBusEngineWillStartDecode" object:[NSNumber numberWithInt:4]];			
		
		[[NSNotificationCenter defaultCenter] postNotificationName:@"JONTUBusEngineWillDecodeStops" object:nil];
		stops = [[aDecoder decodeObjectForKey:@"stops"] retain];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"JONTUBusEngineDidDecodeStops" object:nil];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:@"JONTUBusEngineWillDecodeRoutes" object:nil];
		routes = [[aDecoder decodeObjectForKey:@"routes"] retain];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"JONTUBusEngineDidDecodeRoutes" object:nil];

		[[NSNotificationCenter defaultCenter] postNotificationName:@"JONTUBusEngineWillDecodeBuses" object:nil];
		buses = [[aDecoder decodeObjectForKey:@"buses"] retain];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"JONTUBusEngineDidDecodeBuses" object:nil];

		[[NSNotificationCenter defaultCenter] postNotificationName:@"JONTUBusEngineWillDecodePageCache" object:nil];
		indexPageCache = [[aDecoder decodeObjectForKey:@"indexPageCache"] retain];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"JONTUBusEngineDidDecodePageCache" object:nil];
		
		lastGetIndexPage = [[aDecoder decodeObjectForKey:@"lastGetIndexPage"] retain];
		dirty = [aDecoder decodeBoolForKey:@"dirty"];
		holdCache = [aDecoder decodeIntForKey:@"holdCache"];
		brandNew = NO;

		[[NSNotificationCenter defaultCenter] postNotificationName:@"JONTUBusEngineDidStartDecode" object:nil];
		
	}
	return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder {
	NSLog(@"Encoding engine object");	
	[aCoder encodeObject:stops forKey:@"stops"];
	[aCoder encodeObject:routes forKey:@"routes"];
	[aCoder encodeObject:buses forKey:@"buses"];
	[aCoder encodeObject:indexPageCache forKey:@"indexPageCache"];
	[aCoder encodeObject:lastGetIndexPage forKey:@"lastGetIndexPage"];
	[aCoder encodeBool:dirty forKey:@"dirty"];
	[aCoder encodeInt:holdCache forKey:@"holdCache"];
	
}

-(void)start {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"JONTUBusEngineWillStartCacheLoad" object:[NSNumber numberWithInt:3]];	

	/*
	[buses removeAllObjects];	
	[routes removeAllObjects];
	[stops removeAllObjects];
	 */
	
	// start baseline initialisation.
	[[NSNotificationCenter defaultCenter] postNotificationName:@"JONTUBusEngineWillStartStopsCacheLoad" object:nil];	
	[self stopsWithRefresh:YES]; // has to be first
	[[NSNotificationCenter defaultCenter] postNotificationName:@"JONTUBusEngineDidStartStopsCacheLoad" object:nil];	

	[[NSNotificationCenter defaultCenter] postNotificationName:@"JONTUBusEngineWillStartRoutesCacheLoad" object:nil];	
	[self routesWithRefresh:YES]; // has to be second
	[[NSNotificationCenter defaultCenter] postNotificationName:@"JONTUBusEngineDidStartRoutesCacheLoad" object:nil];	

	[[NSNotificationCenter defaultCenter] postNotificationName:@"JONTUBusEngineWillStartBusesCacheLoad" object:nil];	
	[self busesWithRefresh:YES]; // has to be last
	[[NSNotificationCenter defaultCenter] postNotificationName:@"JONTUBusEngineDidStartBusesCacheLoad" object:nil];	

	brandNew = NO;	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"JONTUBusEngineDidStartCacheLoad" object:nil];
	
}

-(JONTUBusStop *)stopForId:(NSUInteger)stopid {
	for (JONTUBusStop *stop in [self stops]) {
		if ([stop busstopid] == stopid) {
			return stop;
		}
	}
	return nil;
}

-(JONTUBusStop *)stopForCode:(NSString *)code {
	for (JONTUBusStop *stop in [self stops]) {
		if ([[stop code] isEqualToString:code]) {
			return stop;
		}
	}
	return nil;
}

-(NSArray *)stops {
	if (dirty) {
		dirty = NO;
		[self start];
	}
	return [self stopsWithRefresh:NO];
}

-(NSArray *)stopsWithRefresh:(BOOL)refresh {
	if (refresh) {
		NSString *matchString = [[NSString alloc] initWithData:[self getIndexPage] encoding:NSASCIIStringEncoding];
		NSArray *busstops = [matchString arrayOfCaptureComponentsMatchedByRegex:regexBusStop];
		NSArray *otherBuses = nil;
		JONTUBusStop *stop;
		
		NSMutableArray *tempstops = [NSMutableArray arrayWithCapacity:0];
		
		[matchString release];
			
		for (int i=0;i<[busstops count];i++) {

			if ([[[busstops objectAtIndex:i] objectAtIndex:9] length] > 0) {
				otherBuses = [[[[busstops objectAtIndex:i] objectAtIndex:9] stringByReplacingOccurrencesOfString:@" " withString:@" "] componentsSeparatedByString:@","];
			} else {
				otherBuses = nil;
			}
			
			stop = [[JONTUBusStop alloc] initWithID:[[[busstops objectAtIndex:i] objectAtIndex:1] intValue] 
											   code:[[busstops objectAtIndex:i] objectAtIndex:2]
										description:[[busstops objectAtIndex:i] objectAtIndex:3] 
										   roadName:[[busstops objectAtIndex:i] objectAtIndex:4]
										 longtitude:[[busstops objectAtIndex:i] objectAtIndex:7]
										   latitude:[[busstops objectAtIndex:i] objectAtIndex:8]
										 otherBuses:otherBuses];
			[tempstops addObject:stop];
			[stop release];
		}
		[stops release];
		stops = [tempstops retain];
	}
	return stops;
}

-(JONTUBusRoute *)routeForId:(NSUInteger)routeid {
	for (JONTUBusRoute *route in [self routes]) {
		if ([route routeid] == routeid) {
			return route;
		}
	}
	return nil;
}

-(JONTUBusRoute *)routeForName:(NSString *)routename {
	for (JONTUBusRoute *route in [self routes]) {
		if ([[route name] hasPrefix:routename]) {
			return route;
		}
	}
	return nil;
	
}

-(NSArray *)routes {
	if (dirty) {
		dirty = NO;		
		[self start];
	}
	
	return [self routesWithRefresh:NO];
}

-(NSArray *)routesWithRefresh:(BOOL)refresh {
	
	if (refresh) {	
		NSString *matchString = [[NSString alloc] initWithData:[self getIndexPage] encoding:NSASCIIStringEncoding];
		NSArray *busroutes = [matchString arrayOfCaptureComponentsMatchedByRegex:regexRoute];
		JONTUBusRoute *route;
		
		NSMutableArray *temproutes = [NSMutableArray arrayWithCapacity:0];
		[matchString release];	
		
		for (int i=0;i<[busroutes count];i++) {
			NSString *plines = [[busroutes objectAtIndex:i] objectAtIndex:7];
			NSArray *UTMCoords = [plines arrayOfCaptureComponentsMatchedByRegex:regexRoutePolylines];
			
			NSMutableArray *routingInformation = [NSMutableArray arrayWithCapacity:[UTMCoords count]];
			JOUTM *vertex = nil;
			
			for (int q=0;q<[UTMCoords count];q++) {
				
				vertex = [[JOUTM alloc] initWithX:[[[UTMCoords objectAtIndex:q] objectAtIndex:1] doubleValue]
												Y:[[[UTMCoords objectAtIndex:q] objectAtIndex:2] doubleValue]
											 zone:48 
								  SouthHemisphere:NO];
				[routingInformation addObject:vertex];
				[vertex release];
			}
			
			route = [[JONTUBusRoute alloc] initWithID:[[[busroutes objectAtIndex:i] objectAtIndex:1] intValue] 
												 name:[[busroutes objectAtIndex:i] objectAtIndex:2] 
												color:[[busroutes objectAtIndex:i] objectAtIndex:5]
											 colorAlt:[[busroutes objectAtIndex:i] objectAtIndex:6]
												stops:nil
											 polylines:routingInformation];
			route.dirty = YES;
			[temproutes addObject:route];
			[route release];
			
		}
		[routes release];
		routes = [temproutes retain];
	}
	
	return routes;
}

-(JONTUBus *)busForPlate:(NSString *)plate {
	for (JONTUBus *bus in buses) {
		if ([[bus busPlate] isEqualToString:plate]) {
			return bus;
		}
	}
	return nil;
}

-(NSArray *)buses {
	if (dirty) {
		dirty = NO;		
		[self start];
	}
	
	return [self busesWithRefresh:NO];
}

-(NSArray *)busesWithRefresh:(BOOL)refresh {
	if (refresh) {
		
		NSXMLParser *parser = [[NSXMLParser alloc] initWithData:[self sendXHRToURL:getBusPosition PostValues:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%f", (float)arc4random()/10000000000] forKey:@"r"]]];
		
		[parser setDelegate:self];
		[parser setShouldProcessNamespaces:NO];
		[parser setShouldReportNamespacePrefixes:NO];
		[parser setShouldResolveExternalEntities:NO];
		
		[parser parse];
		[parser release];
		
	}
	
	return buses;
}

- (void)parserDidStartDocument:(NSXMLParser *)parser {
	[tempbuses release];
	tempbuses = [[NSMutableArray arrayWithCapacity:0] retain];
}


-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
	JONTUBus *bus;
	
	if ([elementName isEqualToString:@"device"]) {
		NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
		[f setNumberStyle:NSNumberFormatterNoStyle];
		
		bus = [[JONTUBus alloc] initWithID:[[attributeDict objectForKey:@"id"] intValue]
									 route:[self routeForName:[attributeDict objectForKey:@"routename"]] 
							   plateNumber:[attributeDict objectForKey:@"name"] 
								longtitude:[f numberFromString:[attributeDict objectForKey:@"lon"]]
								  latitude:[f numberFromString:[attributeDict objectForKey:@"lat"]]
									 speed:[[attributeDict objectForKey:@"speed"] intValue]
									  hide:([attributeDict objectForKey:@"stat"] == @"hide")?YES:NO 
							   iscDistance:[f numberFromString:[attributeDict objectForKey:@"iscdistance"]]];
		[tempbuses addObject:bus];
		
		[f release];
		[bus release];
	}
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
	[buses release];
	buses = [tempbuses retain];
	[tempbuses release], tempbuses = nil;
}

-(NSData *) getIndexPage {
	if (holdCache < 0) {
		if (indexPageCache == nil) {
			indexPageCache = [[self sendXHRToURL:indexPage PostValues:nil] retain];
 			lastGetIndexPage = [[NSDate date] retain];
		} else {
			return indexPageCache;
		}
	} else {
		if (indexPageCache == nil) {
			indexPageCache = [[self sendXHRToURL:indexPage PostValues:nil] retain];
			lastGetIndexPage = [[NSDate date] retain];
		}		
		if ([[NSDate date] timeIntervalSinceDate:lastGetIndexPage] > holdCache) {
			[indexPageCache release];
			indexPageCache = [[self sendXHRToURL:indexPage PostValues:nil] retain];
			[lastGetIndexPage release];
			lastGetIndexPage = nil;
			lastGetIndexPage = [[NSDate date] retain];
			dirty = YES;
		}		
	}
	return indexPageCache;
}

-(NSData *) sendXHRToURL:(NSString *)url PostValues:(NSDictionary *)postValues {

	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];

	if (postValues != nil) {
	
		NSMutableString *post = [NSMutableString string];
		for (NSString *key in postValues) {
			if ([post length] > 0) {
				[post appendString:@"&"];
			}
			[post appendFormat:@"%@=%@",key,[postValues objectForKey:key]];
		}
		
		NSLog(@"Post String: %@", post);
		NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
		NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
		[request setHTTPMethod:@"POST"];
		[request setValue:postLength forHTTPHeaderField:@"Content-Length"];
		[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
		[request setValue:HTTP_USER_AGENT forHTTPHeaderField:@"User-Agent"];
		[request setHTTPBody:postData];
		
	}
	[request setTimeoutInterval:20];
	
	[request setURL:[NSURL URLWithString:url]];
	
	NSData *recvData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
	
	[request release];
	
	return recvData;
}

-(void)dealloc {
	[lastGetIndexPage release];
	[indexPageCache release];
	[buses release];
	[stops release];
	[routes release];
	[super dealloc];
}

@end
