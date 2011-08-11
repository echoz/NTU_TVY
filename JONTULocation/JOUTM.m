//
//  JOUTM.m
//  Edventurous
//
//  Created by Jeremy Foo on 10/7/10.
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

//  With code from http://home.hiwaay.net/~taylorc/toolbox/geography/geoutm.html
//  by Chuck Taylor used with Permission

#import "JOUTM.h"
#import <math.h>

typedef struct {
	double x;
	double y;
} JOMapXY;

typedef struct {
	JOMapXY xy;
	int zone;
	BOOL southHemi;
} JOUTMCoordinate;

// UTMMethods are "private"
@interface JOUTM (UTMMethods)
-(double) DegToRad:(double)deg;
-(double) RadToDeg:(double)rad;
-(long double) ArcLengthOfMeridian:(long double)phi;
-(double) UTMCentralMeridian:(int)zone;
-(double) FootpointLatitude:(double)y;
-(CLLocation *) LatLonFromMapX:(double)x Y:(double)y lambda0:(double)lambda0;
-(CLLocation *) LatLonFromUTMCoordinateX:(double)x Y:(double)y Zone:(int)zone SouthHemisphere:(BOOL) southhemi;
-(JOUTMCoordinate) UTMCoordinateFromLatitude:(double)lat Longitude:(double)lon;
-(JOMapXY) MapXYFromLatLonWithPhi:(double)phi lambda:(double)lambda lambda0:(double)lambda0;

@end

@implementation JOUTM (UTMethods) 

#define PI 3.14159265358979
// ellipsoid model constants (actual values here are for WGS84)
#define SM_A (double)6378137.0
#define SM_B (double)6356752.314
#define SM_ECCSQUARED (double)6.69437999013e-03
#define UTM_SCALEFACTOR (double)0.9996

/*
 * DegToRad
 *
 * Converts degrees to radians.
 *
 */
-(double) DegToRad:(double)deg
{
	return (double)(deg / 180.0 * PI);
}




/*
 * RadToDeg
 *
 * Converts radians to degrees.
 *
 */
-(double) RadToDeg:(double)rad
{
	return (double)(rad / PI * 180.0);
}




/*
 * ArcLengthOfMeridian
 *
 * Computes the ellipsoidal distance from the equator to a point at a
 * given latitude.
 *
 * Reference: Hoffmann-Wellenhof, B., Lichtenegger, H., and Collins, J.,
 * GPS: Theory and Practice, 3rd ed.  New York: Springer-Verlag Wien, 1994.
 *
 * Inputs:
 *     phi - Latitude of the point, in radians.
 *
 * Globals:
 *     SM_A - Ellipsoid model major axis.
 *     SM_B - Ellipsoid model minor axis.
 *
 * Returns:
 *     The ellipsoidal distance of the point from the equator, in meters.
 *
 */
-(long double) ArcLengthOfMeridian:(long double)phi
{
	long double alpha, beta, gamma, delta, epsilon, n;
	long double result;
	
	/* Precalculate n */
	n = (SM_A - SM_B) / (SM_A + SM_B);
	
	/* Precalculate alpha */
	alpha = ((SM_A + SM_B) / 2.0)
	* (1.0 + (pow (n, 2.0) / 4.0) + (pow (n, 4.0) / 64.0));
	
	/* Precalculate beta */
	beta = (-3.0 * n / 2.0) + (9.0 * pow (n, 3.0) / 16.0)
	+ (-3.0 * pow (n, 5.0) / 32.0);
	
	/* Precalculate gamma */
	gamma = (15.0 * pow (n, 2.0) / 16.0)
	+ (-15.0 * pow (n, 4.0) / 32.0);
    
	/* Precalculate delta */
	delta = (-35.0 * pow (n, 3.0) / 48.0)
	+ (105.0 * pow (n, 5.0) / 256.0);
    
	/* Precalculate epsilon */
	epsilon = (315.0 * pow (n, 4.0) / 512.0);
    
    /* Now calculate the sum of the series and return */
    result = alpha
	* (phi + (beta * sin (2.0 * phi))
	   + (gamma * sin (4.0 * phi))
	   + (delta * sin (6.0 * phi))
	   + (epsilon * sin (8.0 * phi)));
	
    return (long double)result;
}



/*
 * UTMCentralMeridian
 *
 * Determines the central meridian for the given UTM zone.
 *
 * Inputs:
 *     zone - An integer value designating the UTM zone, range [1,60].
 *
 * Returns:
 *   The central meridian for the given UTM zone, in radians, or zero
 *   if the UTM zone parameter is outside the range [1,60].
 *   Range of the central meridian is the radian equivalent of [-177,+177].
 *
 */
-(double) UTMCentralMeridian:(int)zone
{
	return (double)[self DegToRad:(-183.0 + ((double)zone * 6.0))];
}



/*
 * FootpointLatitude
 *
 * Computes the footpoint latitude for use in converting transverse
 * Mercator coordinates to ellipsoidal coordinates.
 *
 * Reference: Hoffmann-Wellenhof, B., Lichtenegger, H., and Collins, J.,
 *   GPS: Theory and Practice, 3rd ed.  New York: Springer-Verlag Wien, 1994.
 *
 * Inputs:
 *   y - The UTM northing coordinate, in meters.
 *
 * Returns:
 *   The footpoint latitude, in radians.
 *
 */
-(double) FootpointLatitude:(double)y
{
	double y_, alpha_, beta_, gamma_, delta_, epsilon_, n;
	double result;
	
	/* Precalculate n (Eq. 10.18) */
	n = (SM_A - SM_B) / (SM_A + SM_B);
	
	/* Precalculate alpha_ (Eq. 10.22) */
	/* (Same as alpha in Eq. 10.17) */
	alpha_ = ((SM_A + SM_B) / 2.0)
	* (1 + (pow (n, 2.0) / 4) + (pow (n, 4.0) / 64));
	
	/* Precalculate y_ (Eq. 10.23) */
	y_ = y / alpha_;
	
	/* Precalculate beta_ (Eq. 10.22) */
	beta_ = (3.0 * n / 2.0) + (-27.0 * pow (n, 3.0) / 32.0)
	+ (269.0 * pow (n, 5.0) / 512.0);
	
	/* Precalculate gamma_ (Eq. 10.22) */
	gamma_ = (21.0 * pow (n, 2.0) / 16.0)
	+ (-55.0 * pow (n, 4.0) / 32.0);
	
	/* Precalculate delta_ (Eq. 10.22) */
	delta_ = (151.0 * pow (n, 3.0) / 96.0)
	+ (-417.0 * pow (n, 5.0) / 128.0);
	
	/* Precalculate epsilon_ (Eq. 10.22) */
	epsilon_ = (1097.0 * pow (n, 4.0) / 512.0);
	
	/* Now calculate the sum of the series (Eq. 10.21) */
	result = y_ + (beta_ * sin (2.0 * y_))
	+ (gamma_ * sin (4.0 * y_))
	+ (delta_ * sin (6.0 * y_))
	+ (epsilon_ * sin (8.0 * y_));
	
	return (double)result;
}



/*
 * MapLatLonToXY
 *
 * Converts a latitude/longitude pair to x and y coordinates in the
 * Transverse Mercator projection.  Note that Transverse Mercator is not
 * the same as UTM; a scale factor is required to convert between them.
 *
 * Reference: Hoffmann-Wellenhof, B., Lichtenegger, H., and Collins, J.,
 * GPS: Theory and Practice, 3rd ed.  New York: Springer-Verlag Wien, 1994.
 *
 * Inputs:
 *    phi - Latitude of the point, in radians.
 *    lambda - Longitude of the point, in radians.
 *    lambda0 - Longitude of the central meridian to be used, in radians.
 *
 * Outputs:
 *    xy - A 2-element array containing the x and y coordinates
 *         of the computed point.
 *
 * Returns:
 *    The function does not return a value.
 *
 */
-(JOMapXY) MapXYFromLatLonWithPhi:(double)phi lambda:(double)lambda lambda0:(double)lambda0
{
	long double N, nu2, ep2, t, t2, l;
	long double l3coef, l4coef, l5coef, l6coef, l7coef, l8coef;
	long double tmp;
	long double xy[2];
	
	/* Precalculate ep2 */
	ep2 = (pow (SM_A, 2.0) - pow (SM_B, 2.0)) / pow (SM_B, 2.0);
    
	/* Precalculate nu2 */
	nu2 = ep2 * pow (cos (phi), 2.0);
    
	/* Precalculate N */
	N = pow (SM_A, 2.0) / (SM_B * sqrt (1 + nu2));
    
	/* Precalculate t */
	t = tan (phi);
	t2 = t * t;
	tmp = (t2 * t2 * t2) - pow (t, 6.0);
	
	/* Precalculate l */
	l = lambda - lambda0;
	    
	/* Precalculate coefficients for l**n in the equations below
	 so a normal human being can read the expressions for easting
	 and northing
	 -- l**1 and l**2 have coefficients of 1.0 */
	l3coef = 1.0 - t2 + nu2;
    
	l4coef = 5.0 - t2 + 9 * nu2 + 4.0 * (nu2 * nu2);
    
	l5coef = 5.0 - 18.0 * t2 + (t2 * t2) + 14.0 * nu2
	- 58.0 * t2 * nu2;
    
	l6coef = 61.0 - 58.0 * t2 + (t2 * t2) + 270.0 * nu2
	- 330.0 * t2 * nu2;
    
	l7coef = 61.0 - 479.0 * t2 + 179.0 * (t2 * t2) - (t2 * t2 * t2);
    
	l8coef = 1385.0 - 3111.0 * t2 + 543.0 * (t2 * t2) - (t2 * t2 * t2);
	
    
	/* Calculate easting (x) */
	xy[0] = N * cos (phi) * l
	+ (N / 6.0 * pow (cos (phi), 3.0) * l3coef * pow (l, 3.0))
	+ (N / 120.0 * pow (cos (phi), 5.0) * l5coef * pow (l, 5.0))
	+ (N / 5040.0 * pow (cos (phi), 7.0) * l7coef * pow (l, 7.0));
    
	/* Calculate northing (y) */
	xy[1] = [self ArcLengthOfMeridian:phi]
	+ (t / 2.0 * N * pow (cos (phi), 2.0) * pow (l, 2.0))
	+ (t / 24.0 * N * pow (cos (phi), 4.0) * l4coef * pow (l, 4.0))
	+ (t / 720.0 * N * pow (cos (phi), 6.0) * l6coef * pow (l, 6.0))
	+ (t / 40320.0 * N * pow (cos (phi), 8.0) * l8coef * pow (l, 8.0));
    
	JOMapXY mapxy;
	mapxy.x = (double)xy[0];
	mapxy.y = (double)xy[1];
	
	return mapxy;
}



/*
 * MapXYToLatLon
 *
 * Converts x and y coordinates in the Transverse Mercator projection to
 * a latitude/longitude pair.  Note that Transverse Mercator is not
 * the same as UTM; a scale factor is required to convert between them.
 *
 * Reference: Hoffmann-Wellenhof, B., Lichtenegger, H., and Collins, J.,
 *   GPS: Theory and Practice, 3rd ed.  New York: Springer-Verlag Wien, 1994.
 *
 * Inputs:
 *   x - The easting of the point, in meters.
 *   y - The northing of the point, in meters.
 *   lambda0 - Longitude of the central meridian to be used, in radians.
 *
 * Outputs:
 *   philambda - A 2-element containing the latitude and longitude
 *               in radians.
 *
 * Returns:
 *   The function does not return a value.
 *
 * Remarks:
 *   The local variables Nf, nuf2, tf, and tf2 serve the same purpose as
 *   N, nu2, t, and t2 in MapLatLonToXY, but they are computed with respect
 *   to the footpoint latitude phif.
 *
 *   x1frac, x2frac, x2poly, x3poly, etc. are to enhance readability and
 *   to optimize computations.
 *
 */
-(CLLocation *) LatLonFromMapX:(double)x Y:(double)y lambda0:(double)lambda0
{
	
	long double phif, Nf, Nfpow, nuf2, ep2, tf, tf2, tf4, cf;
	long double x1frac, x2frac, x3frac, x4frac, x5frac, x6frac, x7frac, x8frac;
	long double x2poly, x3poly, x4poly, x5poly, x6poly, x7poly, x8poly;

	/* Get the value of phif, the footpoint latitude. */
	phif = [self FootpointLatitude:y];
	
	/* Precalculate ep2 */
	ep2 = (pow (SM_A, 2.0) - pow (SM_B, 2.0))
	/ pow (SM_B, 2.0);
	
	/* Precalculate cos (phif) */
	cf = cos (phif);
		
	/* Precalculate nuf2 */
	nuf2 = ep2 * pow (cf, 2.0);
	
	/* Precalculate Nf and initialize Nfpow */
	Nf = pow (SM_A, 2.0) / (SM_B * sqrt (1 + nuf2));
	Nfpow = Nf;
	
	/* Precalculate tf */
	tf = tan (phif);
	tf2 = tf * tf;
	tf4 = tf2 * tf2;
	
	/* Precalculate fractional coefficients for x**n in the equations
	 below to simplify the expressions for latitude and longitude. */
	x1frac = 1.0 / (Nfpow * cf);
			
	Nfpow *= Nf;   /* now equals Nf**2) */
	x2frac = tf / (2.0 * Nfpow);
		
	Nfpow *= Nf;   /* now equals Nf**3) */
	x3frac = 1.0 / (6.0 * Nfpow * cf);
	
	Nfpow *= Nf;   /* now equals Nf**4) */
	x4frac = tf / (24.0 * Nfpow);
	
	Nfpow *= Nf;   /* now equals Nf**5) */
	x5frac = 1.0 / (120.0 * Nfpow * cf);
	
	Nfpow *= Nf;   /* now equals Nf**6) */
	x6frac = tf / (720.0 * Nfpow);
	
	Nfpow *= Nf;   /* now equals Nf**7) */
	x7frac = 1.0 / (5040.0 * Nfpow * cf);
	
	Nfpow *= Nf;   /* now equals Nf**8) */
	x8frac = tf / (40320.0 * Nfpow);
		
	/* Precalculate polynomial coefficients for x**n.
	 -- x**1 does not have a polynomial coefficient. */
	x2poly = -1.0 - nuf2;
	
	x3poly = -1.0 - 2 * tf2 - nuf2;
	
	x4poly = 5.0 + 3.0 * tf2 + 6.0 * nuf2 - 6.0 * tf2 * nuf2
	- 3.0 * (nuf2 *nuf2) - 9.0 * tf2 * (nuf2 * nuf2);
	
	x5poly = 5.0 + 28.0 * tf2 + 24.0 * tf4 + 6.0 * nuf2 + 8.0 * tf2 * nuf2;
	
	x6poly = -61.0 - 90.0 * tf2 - 45.0 * tf4 - 107.0 * nuf2
	+ 162.0 * tf2 * nuf2;
	
	x7poly = -61.0 - 662.0 * tf2 - 1320.0 * tf4 - 720.0 * (tf4 * tf2);
	
	x8poly = 1385.0 + 3633.0 * tf2 + 4095.0 * tf4 + 1575 * (tf4 * tf2);
	
	/* Calculate latitude */
	long double lat = phif + x2frac * x2poly * (x * x)
	+ x4frac * x4poly * pow (x, 4.0)
	+ x6frac * x6poly * pow (x, 6.0)
	+ x8frac * x8poly * pow (x, 8.0);
	
	/* Calculate longitude */
	long double lon = lambda0 + x1frac * x
	+ x3frac * x3poly * pow (x, 3.0)
	+ x5frac * x5poly * pow (x, 5.0)
	+ x7frac * x7poly * pow (x, 7.0);
	
	return [[[CLLocation alloc] initWithLatitude:[self RadToDeg:lat] longitude:[self RadToDeg:lon]] autorelease];
}




/*
 * LatLonToUTMXY
 *
 * Converts a latitude/longitude pair to x and y coordinates in the
 * Universal Transverse Mercator projection.
 *
 * Inputs:
 *   lat - Latitude of the point, in radians.
 *   lon - Longitude of the point, in radians.
 *   zone - UTM zone to be used for calculating values for x and y.
 *          If zone is less than 1 or greater than 60, the routine
 *          will determine the appropriate zone from the value of lon.
 *
 * Outputs:
 *   xy - A 2-element array where the UTM x and y values will be stored.
 *
 * Returns:
 *   The UTM zone used for calculating the values of x and y.
 *
 */
-(JOUTMCoordinate) UTMCoordinateFromLatitude:(double)lat Longitude:(double)lon
{
	
	int zone = floor ((lon + 180.0) / (double)6) + 1;

	JOMapXY xy = [self MapXYFromLatLonWithPhi:[self DegToRad:lat] lambda:[self DegToRad:lon] lambda0:[self UTMCentralMeridian:zone]];
	
	/* Adjust easting and northing for UTM system. */
	xy.x = xy.x * UTM_SCALEFACTOR + 500000.0;
	xy.y = xy.y * UTM_SCALEFACTOR;
	if (xy.y < 0.0)
		xy.y = xy.y + 10000000.0;
	
	JOUTMCoordinate coord;
	
	coord.xy = xy;
	coord.zone = zone;
	if (lat < 0) {
		coord.southHemi = YES;
	} else {
		coord.southHemi = NO;
	}
	
	return coord;
}



/*
 * UTMXYToLatLon
 *
 * Converts x and y coordinates in the Universal Transverse Mercator
 * projection to a latitude/longitude pair.
 *
 * Inputs:
 *	x - The easting of the point, in meters.
 *	y - The northing of the point, in meters.
 *	zone - The UTM zone in which the point lies.
 *	southhemi - True if the point is in the southern hemisphere;
 *               false otherwise.
 *
 * Outputs:
 *	latlon - A 2-element array containing the latitude and
 *            longitude of the point, in radians.
 *
 * Returns:
 *	The function does not return a value.
 *
 */
-(CLLocation *) LatLonFromUTMCoordinateX:(double)x Y:(double)y Zone:(int)zone SouthHemisphere:(BOOL) southhemi
{

	x -= 500000.0;
	x /= UTM_SCALEFACTOR;
	
	/* If in southern hemisphere, adjust y accordingly. */
	if (southhemi)
        y -= 10000000.0;
	
	y /= UTM_SCALEFACTOR;
	
	double cmeridian = [self UTMCentralMeridian:zone];
	
	return [self LatLonFromMapX:x Y:y lambda0:cmeridian];
	
}

@end

@implementation JOUTM
@synthesize utm_x, utm_y, utm_zone, utm_southHemi, latitude, longitude;

-(id)initWithLocation:(CLLocation *)location {
	if (self = [self initWithLatitude:location.coordinate.latitude Longtitude:location.coordinate.longitude]) {
		
	}
	return self;
}
-(id)initWithLatitude:(double)lat Longtitude:(double)lon {
	if (self = [super init]) {
		
		if ((lon < -180.0) || (180.0 <= lon))
			return nil;
		
		if ((lat < -90.0) || (90.0 < lat))
			return nil;
		
		latitude = lat;
		longitude = lon;
		JOUTMCoordinate coord = [self UTMCoordinateFromLatitude:lat Longitude:lon];
		utm_x = coord.xy.x;
		utm_y = coord.xy.y;
		utm_zone = coord.zone;
		utm_southHemi = coord.southHemi;
	}
	return self;
}

-(id)initWithX:(double)x Y:(double)y zone:(int)zone SouthHemisphere:(BOOL)southhemi {
	if (self = [super init]) {
		
		if ((zone < 1) || (60 < zone)) 
			return nil;
		
		utm_x = x;
		utm_y = y;
		utm_zone = zone;
		utm_southHemi = southhemi;
		CLLocation *location = [self LatLonFromUTMCoordinateX:utm_x Y:utm_y Zone:utm_zone SouthHemisphere:utm_southHemi];
		latitude = location.coordinate.latitude;
		longitude = location.coordinate.longitude;
	}
	return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		utm_x = [aDecoder decodeDoubleForKey:@"utm_x"];
		utm_y = [aDecoder decodeDoubleForKey:@"utm_y"];
		utm_zone = [aDecoder decodeIntForKey:@"utm_zone"];
		utm_southHemi = [aDecoder decodeBoolForKey:@"utm_southHemi"];
		latitude = [aDecoder decodeDoubleForKey:@"latitude"];
		longitude = [aDecoder decodeDoubleForKey:@"longitude"];
	}
	return self;
	
}

-(void)encodeWithCoder:(NSCoder *)aCoder {	
	[aCoder encodeDouble:utm_x forKey:@"utm_x"];
	[aCoder encodeDouble:utm_x forKey:@"utm_y"];
	[aCoder encodeInt:utm_zone forKey:@"utm_zone"];
	[aCoder encodeBool:utm_southHemi forKey:@"utm_southHemi"];
	[aCoder encodeDouble:latitude forKey:@"latitude"];
	[aCoder encodeDouble:longitude forKey:@"longitude"];
	
}

-(CLLocation *)location {	
	return [[[CLLocation alloc] initWithLatitude:latitude longitude:longitude] autorelease];
}
-(CLLocationCoordinate2D)coordinate {
	CLLocationCoordinate2D coord;
	coord.latitude = latitude;
	coord.longitude = longitude;
	
	return coord;
}

-(NSString *)description {
	return [NSString stringWithFormat:@"JOUTM, X: %f, Y: %f, Zone: %i, SouthHemisphere: %@", self.utm_x, self.utm_y, self.utm_zone, (self.utm_southHemi)?@"YES":@"NO"];
}

@end