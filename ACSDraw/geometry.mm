/*
 *  geometry.mm
 *  ACSDraw
 *
 *  Created by alan on Sun Mar 14 2004.
 *  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
 *
 */

#include "geometry.h"
#include "gCurve.h"
#include "gLine.h"

NSRect RectFromPoint(NSPoint pt,float padding,float magnification)
   {
	NSRect r;
	r.origin = pt;
	float pm = padding / magnification;
	r.origin.x -= pm;
	r.origin.y -= pm;
	pm *= 2.0;
	r.size.width = pm;
	r.size.height = pm;
	return r;
   }

void quarter_rects(NSRect inRect,NSRect &blRect,NSRect &tlRect,NSRect &trRect,NSRect &brRect)
   {
	blRect = inRect;
	float w = blRect.size.width/2;
	float h = blRect.size.height/2;
	blRect.size = NSMakeSize(w,h);
	tlRect = blRect;
	tlRect.origin.y += h;
	trRect = tlRect;
	trRect.origin.x += w;
	brRect = blRect;
	brRect.origin.x += w;
   }

NSPoint top_left(NSRect r)
   {
	return NSMakePoint(r.origin.x,r.origin.y + r.size.height);
   }

NSPoint bottom_left(NSRect r)
   {
	return r.origin;
   }

NSPoint top_right(NSRect r)
   {
	return NSMakePoint(r.origin.x + r.size.width,r.origin.y + r.size.height);
   }

NSPoint bottom_right(NSRect r)
   {  
	return NSMakePoint(r.origin.x + r.size.width,r.origin.y);
   }

NSPoint diff_points(NSPoint pt2,NSPoint pt1)
   {
	return NSMakePoint(pt2.x - pt1.x,pt2.y - pt1.y);
   }

NSSize point_offset(NSPoint pt2,NSPoint pt1)
   {
	return NSMakeSize(pt2.x - pt1.x,pt2.y - pt1.y);
   }

NSPoint offset_point(NSPoint pt,NSPoint offset)
   {
	return NSMakePoint(pt.x + offset.x,pt.y + offset.y);
   }

NSPoint offset_point(NSPoint pt,NSSize offset)
   {
	return NSMakePoint(pt.x + offset.width,pt.y + offset.height);
   }

NSSize neg_size(NSSize sz)
   {
	return NSMakeSize(-sz.width,-sz.height);
   }

CGFloat dot_product(NSPoint pt1,NSPoint pt2)
   {
	return (pt1.x * pt2.x + pt1.y * pt2.y);
   }

CGFloat squaredPointDistanceFromLineSegment(NSPoint linePt0,NSPoint linePt1,NSPoint testPoint,
	                       CGFloat &t,NSPoint &hitPointOnLine)
   {
	NSPoint d = diff_points(linePt1,linePt0);										//direction vector
	NSPoint YmP0 = diff_points(testPoint,linePt0);
	CGFloat localt = dot_product(d,YmP0);
	CGFloat DdD = dot_product(d,d);
	t = localt / DdD;
	if (t <= 0)
	   {
		hitPointOnLine = linePt0;
		return (dot_product(YmP0,YmP0));
	   }
	if (t >= 1)
	   {
		hitPointOnLine = linePt1;
		NSPoint YmP1 = diff_points(testPoint,linePt1);
		return (dot_product(YmP1,YmP1));
	   }
	hitPointOnLine.x = linePt0.x + d.x * t;
	hitPointOnLine.y = linePt0.y + d.y * t;
	return (dot_product(YmP0,YmP0) - localt * t);
   }

CGFloat pointDistanceFromLineSegment(NSPoint linePt0,NSPoint linePt1,NSPoint testPoint,
								   CGFloat &t,NSPoint &hitPointOnLine)
   {
	return sqrt(squaredPointDistanceFromLineSegment(linePt0,linePt1,testPoint,
													t,hitPointOnLine));
   }

BOOL testLineSegmentHit(NSPoint linePt0,NSPoint linePt1,NSPoint testPoint,
	                       CGFloat &t,NSPoint &hitPointOnLine,CGFloat &distance,CGFloat threshold)
   {
	distance = pointDistanceFromLineSegment(linePt0,linePt1,testPoint,t,hitPointOnLine);
	return (distance <= threshold);		
   }

#define FLAT_THRESHOLD 0.01

CGFloat flatness(NSPoint centrepoint,NSPoint pt0,NSPoint pt1)
{
	CGFloat dummyFloat;
	NSPoint dummyPoint;
	CGFloat f1 = squaredPointDistanceFromLineSegment(pt0,pt1,centrepoint,dummyFloat,dummyPoint);
	return f1;
}

CGFloat flatness(NSPoint startPt,NSPoint endPt,NSPoint controlPt1,NSPoint controlPt2)
{
	NSPoint pt10 = midPoint(startPt,controlPt1);
	NSPoint pt11 = midPoint(controlPt1,controlPt2);
	NSPoint pt12 = midPoint(controlPt2,endPt);
	NSPoint pt21 = midPoint(pt10,pt11);
	NSPoint pt22 = midPoint(pt11,pt12);
	NSPoint pt33 = midPoint(pt21,pt22);
	return flatness(pt33,startPt,endPt);
}

NSRect expandRectToPoint(NSRect r,NSPoint p)
   {
	if (p.x < r.origin.x)
	   {
		float diff = r.origin.x - p.x;
		r.origin.x = p.x;
		r.size.width += diff;
	   }
	else
	   {
		float maxx = r.origin.x + r.size.width; 
		if (p.x > maxx)
			r.size.width = p.x - r.origin.x;
	   }
	if (p.y < r.origin.y)
	   {
		float diff = r.origin.y - p.y;
		r.origin.y = p.y;
		r.size.height += diff;
	   }
	else
	   {
		float maxy = r.origin.y + r.size.height; 
		if (p.y > maxy)
			r.size.height = p.y - r.origin.y;
	   }
	return r;
   }

NSRect curveBounds(NSPoint p1,NSPoint p2,NSPoint p3,NSPoint p4)
   {
	NSRect r;
	r.origin = p1;
	r.size.width = 0.0;
	r.size.height = 0.0;
	r = expandRectToPoint(r,p2);
	r = expandRectToPoint(r,p3);
	r = expandRectToPoint(r,p4);
	if (r.size.width == 0.0)
		r.size.width = 1.0;
	if (r.size.height == 0.0)
		r.size.height = 1.0;
	return r;
   }

BOOL lineInRect(NSRect r,NSPoint p0,NSPoint p1)
   {
	if (p0.x < NSMinX(r) && p1.x < NSMinX(r))
		return NO;
	if (p0.x > NSMaxX(r) && p1.x > NSMaxX(r))
		return NO;
	if (p0.y < NSMinY(r) && p1.y < NSMinY(r))
		return NO;
	if (p0.y > NSMaxY(r) && p1.y > NSMaxY(r))
		return NO;
	if (NSPointInRect(p0,r) || NSPointInRect(p1,r))
		return YES;
	CGFloat xDiff = (p1.x - p0.x)/2.0;
	CGFloat yDiff = (p1.y - p0.y)/2.0;
	if (fabs(xDiff) < 0.5 && fabs(yDiff) < 0.5)
		return NO;
	NSPoint midPoint = NSMakePoint(p0.x + xDiff,p0.y + yDiff);
	return lineInRect(r,p0,midPoint) || lineInRect(r,midPoint,p1);
   }

NSPoint midPoint(NSPoint p0,NSPoint p1)
   {
	return NSMakePoint(p0.x + (p1.x - p0.x)/2,p0.y + (p1.y - p0.y)/2);
   }

NSPoint tPointAlongLine(CGFloat t,NSPoint p0,NSPoint p1)
   {
	CGFloat dx = p1.x - p0.x;
	CGFloat dy = p1.y - p0.y;
	dx = dx * t;
	dy = dy * t;
	return NSMakePoint(p0.x + dx,p0.y + dy);
   }

CGFloat squaredDistance(NSPoint p0,NSPoint p1)
   {
	NSPoint dp = diff_points(p0,p1);
	return (dp.x * dp.x + dp.y * dp.y);
   }

CGFloat pointDistance(NSPoint p0,NSPoint p1)
   {
	return sqrt(squaredDistance(p0,p1));
   }

NSRect rectFromPoints(NSPoint pt1,NSPoint pt2)
   {
	CGFloat minX = MIN(pt1.x,pt2.x);
	CGFloat minY = MIN(pt1.y,pt2.y);
	CGFloat maxX = MAX(pt1.x,pt2.x);
	CGFloat maxY = MAX(pt1.y,pt2.y);
	return NSMakeRect(minX,minY,maxX-minX,maxY-minY);
   }


BOOL testLineSegmentHit(NSPoint linePt0,NSPoint linePt1,NSPoint testPoint,CGFloat threshold)
   {
	CGFloat t,distance;
	NSPoint hitPointOnLine;
	distance = pointDistanceFromLineSegment(linePt0,linePt1,testPoint,t,hitPointOnLine);
	return (distance <= threshold);		
   }

BOOL testCurveHit(NSPoint startPt,NSPoint endPt,NSPoint controlPt1,NSPoint controlPt2,NSPoint testPoint,
				  CGFloat &t,NSPoint &hitPointOnCurve,CGFloat &distance,CGFloat threshold,CGFloat dist2,CGFloat leftT,CGFloat rightT)
{
	NSRect r = curveBounds(startPt,endPt,controlPt1,controlPt2);
	r = NSInsetRect(r,-threshold,-threshold);
	if (!NSPointInRect(testPoint,r))
		return NO;
	NSPoint pt10 = midPoint(startPt,controlPt1);
	NSPoint pt11 = midPoint(controlPt1,controlPt2);
	NSPoint pt12 = midPoint(controlPt2,endPt);
	//	NSPoint pt20 = midPoint(startPt,pt10);
	NSPoint pt21 = midPoint(pt10,pt11);
	NSPoint pt22 = midPoint(pt11,pt12);
	//	NSPoint pt23 = midPoint(pt12,endPt);
	NSPoint pt33 = midPoint(pt21,pt22);
	if (flatness(pt33,startPt,endPt) < FLAT_THRESHOLD)
	{
		if (testLineSegmentHit(startPt,endPt,testPoint,threshold))
		{
			t = (leftT + rightT) / 2;
			return YES;
		}
		else
			return NO;
	}
	float midT = leftT+(rightT-leftT)/2;
	return (testCurveHit(startPt,pt33,pt10,pt21,testPoint,t,hitPointOnCurve,distance,threshold,dist2,leftT,midT) ||
			testCurveHit(pt33,endPt,pt22,pt12,testPoint,t,hitPointOnCurve,distance,threshold,dist2,midT,rightT));		
}

BOOL nearestPointOnCurve(NSPoint startPt,NSPoint endPt,NSPoint controlPt1,NSPoint controlPt2,NSPoint testPoint,
				CGFloat &t,NSPoint &hitPointOnCurve,CGFloat &distance,CGFloat threshold,CGFloat dist2,CGFloat leftT,CGFloat rightT)
   {
	NSRect r = curveBounds(startPt,endPt,controlPt1,controlPt2);
	r = NSInsetRect(r,-threshold,-threshold);
	if (!NSPointInRect(testPoint,r))
		return NO;
	if (flatness(startPt,endPt,controlPt1,controlPt2) < FLAT_THRESHOLD)
	   {
		CGFloat localt;
		NSPoint localpt;
		CGFloat pdist = pointDistanceFromLineSegment(startPt,endPt,testPoint,localt,localpt);
		if (pdist < distance)
		   {
			distance = pdist;
			hitPointOnCurve = localpt;
			t = (leftT + rightT) / 2;
			return YES;
		   }
		else
			return NO;
	   }
	NSPoint pt10 = midPoint(startPt,controlPt1);
	NSPoint pt11 = midPoint(controlPt1,controlPt2);
	NSPoint pt12 = midPoint(controlPt2,endPt);
//	NSPoint pt20 = midPoint(startPt,pt10);
	NSPoint pt21 = midPoint(pt10,pt11);
	NSPoint pt22 = midPoint(pt11,pt12);
//	NSPoint pt23 = midPoint(pt12,endPt);
	NSPoint pt33 = midPoint(pt21,pt22);
	CGFloat midT = leftT+(rightT-leftT)/2;
	BOOL b1 = nearestPointOnCurve(startPt,pt33,pt10,pt21,testPoint,t,hitPointOnCurve,distance,threshold,dist2,leftT,midT);
	BOOL b2 = nearestPointOnCurve(pt33,endPt,pt22,pt12,testPoint,t,hitPointOnCurve,distance,threshold,dist2,midT,rightT);
	return b1 || b2;		
   }

void splitCurveByT(NSPoint startPt,NSPoint endPt,NSPoint controlPt1,NSPoint controlPt2,CGFloat t,
					NSPoint &c1EndPt,NSPoint &c1CP1,NSPoint &c1CP2,
					NSPoint &c2CP1,NSPoint &c2CP2)
   {
	NSPoint pt10 = tPointAlongLine(t,startPt,controlPt1);
	NSPoint pt11 = tPointAlongLine(t,controlPt1,controlPt2);
	NSPoint pt12 = tPointAlongLine(t,controlPt2,endPt);
	NSPoint pt21 = tPointAlongLine(t,pt10,pt11);
	NSPoint pt22 = tPointAlongLine(t,pt11,pt12);
	NSPoint pt33 = tPointAlongLine(t,pt21,pt22);
	c1EndPt = pt33;
	c1CP1 = pt10;
	c1CP2 = pt21;
	c2CP1 = pt22;
	c2CP2 = pt12;
   }

const double TOLERANCE = 0.0000001;  // Application specific tolerance

NSArray *splitCurveByT(gCurve *inCurve,CGFloat t)
   {
	NSPoint c1EndPt,c1CP1,c1CP2,c2CP1,c2CP2;
	splitCurveByT([inCurve pt1],[inCurve pt2],[inCurve cp1],[inCurve cp2],t,
		c1EndPt,c1CP1,c1CP2,c2CP1,c2CP2);
	return @[[gCurve gCurvePt1:[inCurve pt1] pt2:c1EndPt cp1:c1CP1 cp2:c1CP2],
			 [gCurve gCurvePt1:c1EndPt pt2:[inCurve pt2] cp1:c2CP1 cp2:c2CP2]];
   }

double bezfunc(double t,double c0,double c1,double c2,double c3,double c4)
   {
	double t2 = t * t;
	double t3 = t2 * t;
	double t4 = t3 * t;
	double result = sqrt(c0 + t * c1 + t2 * c2 + t3 * c3 + t4 * c4);
	return result;
   }

double simpson(double a,double b,int maxSteps,double c0,double c1,double c2,double c3,double c4)
   {
	double epsilon = TOLERANCE + 1.0;
	double initialSum = bezfunc(a,c0,c1,c2,c3,c4) + bezfunc(b,c0,c1,c2,c3,c4);
	double lastSum = initialSum,sum=0.0;
	int n = 4;
	while (n <= maxSteps && epsilon >= TOLERANCE)
	   {
		double h = (b - a) / n;
		double h3 = h / 3.0;
		sum = initialSum;
		for (int i = 1;i < n;i+=2)
		   {
			double x = a + i * h;
			sum += 4 * bezfunc(x,c0,c1,c2,c3,c4);
			if (i != n - 1)
			   {
				x = a + (i + 1) * h;
				sum += 2 * bezfunc(x,c0,c1,c2,c3,c4);
			   }
		   }
		sum *= h3;
//		std::cout << std::setprecision(16) << sum << "    " << n << std::endl;
		epsilon = fabs(sum - lastSum);
		lastSum = sum;
		n *= 2;
	   }
	return sum; 
   }

double arcLength(NSPoint pt00,NSPoint pt01,NSPoint pt02,NSPoint pt03,int steps,double minT,double maxT)
   {
	double a1 = 3 * (pt01.x - pt00.x);
	double a2 = 3 * (pt00.x - 2*pt01.x + pt02.x);
	double a3 = -pt00.x + 3 * pt01.x - 3 * pt02.x + pt03.x;
	double b1 = 3 * (pt01.y - pt00.y);
	double b2 = 3 * (pt00.y - 2*pt01.y + pt02.y);
	double b3 = -pt00.y + 3 * pt01.y - 3 * pt02.y + pt03.y;
	double c0 = (a1 * a1) + (b1 * b1);
	double c1 = 4 * (a1 * a2 + b1 * b2);
	double c2 = 6 * (a1 * a3 + b1 * b3) + 4 * (a2 * a2 + b2 * b2);
	double c3 = 12 * (a2 * a3 + b2 * b3);
	double c4 = 9 * (a3 * a3 + b3 * b3);
	return simpson(minT,maxT,steps,c0,c1,c2,c3,c4);
   }

double sForT(gCurve *inCurve,CGFloat t)
{
    gCurve *lCurve,*rCurve;
    NSArray *arr = splitCurveByT(inCurve,t);
	lCurve = arr[0];
	rCurve = arr[1];
    double wholelen = arcLength(inCurve.pt1,inCurve.cp1,inCurve.cp2,inCurve.pt2,64,0.0,1.0);
    double leftlen = arcLength(lCurve.pt1,lCurve.cp1,lCurve.cp2,lCurve.pt2,64,0.0,1.0);
    return leftlen / wholelen;
}

double tForS(NSPoint pt00,NSPoint pt01,NSPoint pt02,NSPoint pt03,int steps,double s,double arclength)
   {
	if (s == 1.0)
		return s;
	double lbound=0.0,rbound=1.0,lboundS=0.0,rboundS=1.0;
	double guessT,valueS,epsilon;
	guessT = s;
	valueS = arcLength(pt00,pt01,pt02,pt03,64,0.0,guessT) / arclength;
	epsilon = valueS - s;
	for (int i = 0;i < steps && fabs(epsilon) >= TOLERANCE;i++)
	   {
		double ratio = (s - lboundS) / (valueS - lboundS);
		double nextGuess = lbound + (guessT - lbound) * ratio;
		if (epsilon < 0.0)
		   {
			lboundS = valueS;
			lbound = guessT;
		   }
		else
		   {
			rboundS = valueS;
			rbound = guessT;
		   }
		guessT = nextGuess;
		valueS = arcLength(pt00,pt01,pt02,pt03,64,0.0,guessT) / arclength;
		epsilon = valueS - s;
	   }
	return guessT;
   }

BOOL lineIntersectsWithBoundingBox(NSPoint linePt1,NSPoint linePt2,NSRect bBox)	// Wrong!
   {
	float minX = bBox.origin.x;
	float minY = bBox.origin.y;
	float maxX = minX + bBox.size.width;
	float maxY = minY + bBox.size.height;
	if ((linePt1.x <= minX && linePt2.x <= minX) ||
		(linePt1.x >= maxX && linePt2.x >= maxX) ||
		(linePt1.y >= maxY && linePt2.y >= maxY) ||
		(linePt1.y <= minY && linePt2.y <= minY))
		return NO;
	if (NSPointInRect(linePt1,bBox) || NSPointInRect(linePt2,bBox))
		return YES;
	NSPoint lPoint;
	NSPoint rPoint;
	if (linePt1.x < linePt2.x)
	   {
		lPoint = linePt1;
		rPoint = linePt2;
	   }
	else
	   {
		lPoint = linePt2;
		rPoint = linePt1;
	   }
	NSPoint d = NSMakePoint(rPoint.x - lPoint.x,rPoint.y - lPoint.y);
	if (lPoint.x < minX)
	   {
		float t = (minX - lPoint.x) / d.x;
		float y = lPoint.y + t * d.y;
		if (y > minY && y < maxY)
			return YES;
	   }
	else if (lPoint.x < maxX)
	   {
		float t = (maxX - lPoint.x) / d.x;
		float y = lPoint.y + t * d.y;
		if (y > minY && y < maxY)
			return YES;
	   }
	return NO;
   }

BOOL lineSegmentsIntersect(NSPoint a,NSPoint b,NSPoint c,NSPoint d,NSPoint &intersectPoint)
   {
	double s,t,num,denom;
	denom = a.x * (d.y - c.y) +
			b.x * (c.y - d.y) +
			d.x * (b.y - a.y) +
			c.x * (a.y - b.y);
	if (denom == 0.0)							// lines are parallel
		return NO;
	num =   a.x * (d.y - c.y) +
			c.x * (a.y - d.y) +
			d.x * (c.y - a.y);
	if (num == 0.0 || num == denom)
		return NO;
	s = num/denom;
	num = -(a.x * (c.y - b.y) +
			b.x * (a.y - c.y) +
			c.x * (b.y - a.y));
	if (num == 0.0 || num == denom)
		return NO;
	t = num/denom;
	if (s > 0.0 && s < 1.0 && t > 0.0 && t < 1.0)
	   {
		intersectPoint.x = a.x + s * (b.x - a.x);
		intersectPoint.y = a.y + s * (b.y - a.y);
		return YES;
	   }
	return NO;
   }

BOOL linesIntersect(NSPoint a,NSPoint b,NSPoint c,NSPoint d,NSPoint &intersectPoint)
   {
	double s,t,num,denom;
	denom = a.x * (d.y - c.y) +
			b.x * (c.y - d.y) +
			d.x * (b.y - a.y) +
			c.x * (a.y - b.y);
	if (denom == 0.0)							// lines are parallel
		return NO;
	num =   a.x * (d.y - c.y) +
			c.x * (a.y - d.y) +
			d.x * (c.y - a.y);
	if (num == 0.0 || num == denom)
		return NO;
	s = num/denom;
	num =   -(a.x * (c.y - b.y) +
			b.x * (a.y - c.y) +
			c.x * (b.y - a.y));
	if (num == 0.0 || num == denom)
		return NO;
	t = num/denom;
	intersectPoint.x = a.x + s * (b.x - a.x);
	intersectPoint.y = a.y + s * (b.y - a.y);
	return YES;
   }

NSPoint lperp(NSPoint d)						//returns difference vector perpendicular to d (left-hand)
   {
	NSPoint od;
	od.x = -d.y;
	od.y = d.x;
	return od;
   }

NSPoint rperp(NSPoint d)						//returns difference vector perpendicular to d (right-hand)
   {
	NSPoint od;
	od.x = d.y;
	od.y = -d.x;
	return od;
   }

CGFloat dlen(NSPoint d)							//length of difference vector
   {
	return sqrt(d.x * d.x + d.y * d.y);
   }

NSPoint vecMultiply(NSPoint vec,float factor)
{
    return NSMakePoint(vec.x*factor, vec.y * factor);
}

void getOutlineLine(gLine *inLine,NSMutableArray *list,float offset)
   {
	NSPoint fromPt = [inLine fromPt];
	NSPoint toPt = [inLine toPt];
	NSPoint d = diff_points(toPt,fromPt);		//difference vector
	NSPoint perpD = lperp(d);					//perpendicular to difference vector
	float t = offset / dlen(perpD);					//relates t to the length of the difference vector
	float dx = perpD.x * t;
	float dy = perpD.y * t;
	NSPoint lFromPt,lToPt;
	lFromPt.x = fromPt.x + dx;
	lFromPt.y = fromPt.y + dy;
	lToPt.x = toPt.x + dx;
	lToPt.y = toPt.y + dy;
	gLine *gl = [gLine gLineFrom:lFromPt to:lToPt direction:[inLine direction]];
	[gl calculateDirectionVectors];
	[list addObject:gl];
   }

void outlineLine(gLine *inLine,float strokeWidth,		//outline a straight line
				 NSMutableArray *leftLines,NSMutableArray *rightLines)
   {
	float w2 = strokeWidth / 2;
	getOutlineLine(inLine,leftLines,w2);
	getOutlineLine(inLine,rightLines,-w2);
   }


void bzTangent(gCurve *inCurve,CGFloat t,NSPoint &b30,NSPoint &d) //uses deCasteljau algorithm to output point and tangent at t
   {
	NSPoint b10,b11,b12,b20,b21,pt1,pt2,cp1,cp2;
	pt1 = [inCurve pt1];
	pt2 = [inCurve pt2];
	cp1 = [inCurve cp1];
	cp2 = [inCurve cp2];
	b10 = tPointAlongLine(t,pt1,cp1);
	b11 = tPointAlongLine(t,cp1,cp2);
	b12 = tPointAlongLine(t,cp2,pt2);
	b20 = tPointAlongLine(t,b10,b11);
	b21 = tPointAlongLine(t,b11,b12);
	b30 = tPointAlongLine(t,b20,b21);
	d.x = b21.x - b30.x;
	d.y = b21.y - b30.y;
   }

void bzNormal(gCurve *inCurve,CGFloat t,NSPoint &b30,NSPoint &d) //uses deCasteljau algorithm to output point at t and normal vector
   {
	bzTangent(inCurve,t,b30,d);
	d = lperp(d);
   }

void getXorYC(CGFloat x1,CGFloat x2,CGFloat xi,CGFloat xj,CGFloat t,	//given x1 and x2 - the xvalues for the 2 control points,
			  CGFloat &rxc1,CGFloat &rxc2)						//xi and xj, two points on the curve at t and (1 - t)
															//returns x values for each control point
															//does the same for y values
   {
	CGFloat xc1Coef1,xc2Coef1,xc1Coef2,xc2Coef2,rhs1,rhs2,
		oneMt,												// (1-t)
		oneMt2;												// (1-t) squared
	oneMt = 1 - t;
	oneMt2 = oneMt * oneMt;
	rhs1 = xi - (x1 * oneMt2 * oneMt) - (x2 * t * t * t);
	xc1Coef1 = 3.0 * t * oneMt2;
	xc2Coef1 = 3.0 * t * t * oneMt;
	t = 1 - t;
	oneMt = 1 - t;
	oneMt2 = oneMt * oneMt;
	rhs2 = xj - (x1 * oneMt2 * oneMt) - (x2 * t * t * t);
	xc1Coef2 = 3.0 * t * oneMt2;
	xc2Coef2 = 3.0 * t * t * oneMt;
															//eliminate xc2
	CGFloat factor = xc2Coef1 / xc2Coef2;
	rxc1 = (rhs1 - (rhs2 * factor)) / (xc1Coef1 - (xc1Coef2 * factor));
															//eliminate xc1
	factor = xc1Coef1 / xc1Coef2;
	rxc2 = (rhs1 - (rhs2 * factor)) / (xc2Coef1 - (xc2Coef2 * factor));
   }

BOOL curveError(gCurve *newCurve,gCurve *originalCurve,CGFloat offset,CGFloat errorThreshold)
   {
	for (int i = 1;i < 10;i++)
	   {
		CGFloat t = i * 0.1;
		NSPoint nPt,oPt,d;
		bzNormal(newCurve,t,nPt,d);
		bzNormal(originalCurve,t,oPt,d);
		CGFloat dLen = dlen(d);
		if (dLen == 0)
			t = 0.0;
		else
			t = offset / dLen;
		CGFloat dx = d.x * t;
		CGFloat dy = d.y * t;
		oPt.x += dx;
		oPt.y += dy;
		if (dlen(diff_points(nPt,oPt)) > errorThreshold)
			return YES;
	   }
	return NO;
   }

void getOutlineCurve(gCurve *inCurve,NSMutableArray *curveList,CGFloat offset)
{
	NSPoint pt1 = [inCurve pt1];
	NSPoint pt2 = [inCurve pt2];
	NSPoint cp1 = [inCurve cp1];
	NSPoint cp2 = [inCurve cp2];
	if (flatness(pt1,pt2,cp1,cp2) < FLAT_THRESHOLD)
	{
		gLine *gl = [gLine gLineFrom:pt1 to:pt2 direction:[inCurve direction]];
		[gl calculateDirectionVectors];
		[curveList addObject:gl];
		return;
	}
	NSPoint ptx;
	CGFloat dx,dy,t,dLen;
	if (NSEqualPoints(cp1,pt1))
		ptx = cp2;
	else
		ptx = cp1;
	NSPoint d1 = diff_points(ptx,pt1);			//difference vector
	NSPoint perpD = lperp(d1);					//perpendicular to difference vector
	dLen = dlen(perpD);
	if (dLen == 0)
		t = 0.0;
	else
		t = offset / dLen;						//relates t to the length of the difference vector
	dx = perpD.x * t;
	dy = perpD.y * t;
	NSPoint newPt1;
	newPt1.x = pt1.x + dx;
	newPt1.y = pt1.y + dy;
	if (NSEqualPoints(cp2,pt2))
		ptx = cp1;
	else
		ptx = cp2;
	NSPoint d2 = diff_points(pt2,ptx);			//difference vector
	perpD = lperp(d2);
	dLen = dlen(perpD);
	if (dLen == 0)
		t = 0.0;
	else
		t = offset / dLen;						//relates t to the length of the difference vector
	dx = perpD.x * t;
	dy = perpD.y * t;
	NSPoint newPt2;
	newPt2.x = pt2.x + dx;
	newPt2.y = pt2.y + dy;
	NSPoint newCp1;
	NSPoint newCp2;
	if (NSEqualPoints(pt1,cp1))
	{
		NSPoint newpt1prime = offset_point(newPt1,d1);
		NSPoint newpt2prime = offset_point(newPt2,d2);
		linesIntersect(newPt1,newpt1prime,newPt2,newpt2prime,newCp2);
		newCp1 = newPt1;
	}
	else if (NSEqualPoints(pt2,cp2))
	{
		NSPoint newpt1prime = offset_point(newPt1,d1);
		NSPoint newpt2prime = offset_point(newPt2,d2);
		linesIntersect(newPt1,newpt1prime,newPt2,newpt2prime,newCp1);
		newCp2 = newPt2;
	}
	else
	{
		NSPoint tempPt;
		bzNormal(inCurve,(1.0 / 3.0),tempPt,perpD);
		dLen = dlen(perpD);
		if (dLen == 0)
			t = 0.0;
		else
			t = offset / dLen;						//relates t to the length of the difference vector
		dx = perpD.x * t;
		dy = perpD.y * t;
		NSPoint pi;
		pi.x = tempPt.x + dx;
		pi.y = tempPt.y + dy;
		bzNormal(inCurve,(2.0 / 3.0),tempPt,perpD);
		dLen = dlen(perpD);
		if (dLen == 0)
			t = 0.0;
		else
			t = offset / dLen;				//relates t to the length of the difference vector
		dx = perpD.x * t;
		dy = perpD.y * t;
		NSPoint pj;
		pj.x = tempPt.x + dx;
		pj.y = tempPt.y + dy;
		getXorYC(newPt1.x,newPt2.x,pi.x,pj.x,(1.0 / 3.0),newCp1.x,newCp2.x);
		getXorYC(newPt1.y,newPt2.y,pi.y,pj.y,(1.0 / 3.0),newCp1.y,newCp2.y);
		if (d1.x == 0.0 || newCp1.x == newPt1.x)
		{
			CGFloat ratio = (newCp1.y - newPt1.y) / d1.y;
			newCp1.x = newPt1.x + ratio * d1.x;
		}
		else
		{
			CGFloat ratio = (newCp1.x - newPt1.x) / d1.x;
			newCp1.y = newPt1.y + ratio * d1.y;
		}
		if (d2.x == 0.0 || newCp2.x == newPt2.x)
		{
			CGFloat ratio = (newCp2.y - newPt2.y) / d2.y;
			newCp2.x = newPt2.x + ratio * d2.x;
		}
		else
		{
			CGFloat ratio = (newCp2.x - newPt2.x) / d2.x;
			newCp2.y = newPt2.y + ratio * d2.y;
		}
	}
	gCurve *gc = [gCurve gCurvePt1:newPt1 pt2:newPt2 cp1:newCp1 cp2:newCp2];
	if (curveError(gc,inCurve,offset,1.0))
	{
		gCurve *lCurve,*rCurve;
		NSArray *arr = splitCurveByT(inCurve,0.5);
		lCurve = arr[0];
		rCurve = arr[1];
		
		getOutlineCurve(lCurve,curveList,offset);
		getOutlineCurve(rCurve,curveList,offset);
	}
	else
	{
		[gc calculateDirectionVectors];
		[curveList addObject:gc];
	}
}

void outlineCurve(gCurve *inCurve,NSMutableArray *leftLines,NSMutableArray *rightLines,CGFloat strokeWidth)
   {
	if (NSEqualPoints([inCurve pt1],[inCurve cp1]) && NSEqualPoints([inCurve pt2],[inCurve cp2]))
	   {
		outlineLine([gLine gLineFrom:[inCurve pt1] to:[inCurve pt2] direction:[inCurve direction]],strokeWidth,leftLines,rightLines);
		return;
	   }
	CGFloat w2 = strokeWidth / 2;
	NSUInteger lind = [leftLines count]; 
	NSUInteger rind = [rightLines count]; 
	getOutlineCurve(inCurve,leftLines,w2);
	[[leftLines objectAtIndex:lind]setDirection:[inCurve direction]];
	[[leftLines objectAtIndex:lind]setStartDirectionVector:[inCurve startDirectionVector]];
	[[leftLines objectAtIndex:[leftLines count]-1]setEndDirectionVector:[inCurve endDirectionVector]];
	getOutlineCurve(inCurve,rightLines,-w2);
	[[rightLines objectAtIndex:rind]setDirection:[inCurve direction]];
	[[rightLines objectAtIndex:rind]setStartDirectionVector:[inCurve startDirectionVector]];
	[[rightLines objectAtIndex:[rightLines count]-1]setEndDirectionVector:[inCurve endDirectionVector]];
   }

void adjust2lines(gLine *line1,gLine *line2)
   {
	NSPoint intersectionPt;
	if (!NSEqualPoints([line1 toPt],[line2 fromPt]) && linesIntersect([line1 fromPt],[line1 toPt],[line2 fromPt],[line2 toPt],intersectionPt))
	   {
		[line1 setToPt:intersectionPt];
		[line2 setFromPt:intersectionPt];
	   }
   }

void adjustLineAndCurve(gLine *line1,gCurve *curve1,bool doingLeft,NSMutableArray* additions)
   {
	if ([curve1 direction] == 0)
		return;
	if (NSEqualPoints([line1 fromPt],[line1 toPt]))
		return;
	NSPoint curvept1 = [curve1 pt1];
	NSPoint curvecp1 = [curve1 cp1];
	if (NSEqualPoints(curvept1,curvecp1))
		curvept1 = [curve1 cp2];
	if (NSEqualPoints(curvept1,curvecp1))
		curvept1 = [curve1 pt2];
	if (NSEqualPoints(curvept1,curvecp1))
		return;
	NSPoint intersectionPt;
	if (([curve1 direction] > 0 && doingLeft) || ([curve1 direction] < 0 && !doingLeft))		//we will intersect with the curve itself
	   {
		NSMutableArray *intersectPoints = [NSMutableArray arrayWithCapacity:10];
		NSMutableArray *os = [NSMutableArray arrayWithCapacity:10];
		NSMutableArray *ot = [NSMutableArray arrayWithCapacity:10];
		bool collinear;
		lineCurveIntersection([line1 fromPt],[line1 toPt],[curve1 pt1],[curve1 pt2],[curve1 cp1],[curve1 cp2],intersectPoints,os,ot,collinear,0.0,1.0,true);
		double mint = 2.0;
		int minind = -1;
		NSUInteger ct = [ot count];
		for (int i = 0;i < ct;i++)
		   {
			double t = [[ot objectAtIndex:i]doubleValue];
			if (t < mint)
			   {
				mint = t;
				minind = i;
			   }
		   }
		if (minind >= 0)
		   {
			intersectionPt = [[intersectPoints objectAtIndex:minind]pointValue];
			[line1 setToPt:intersectionPt];
			NSPoint leftpt3,leftcp1,leftcp2,rightcp1,rightcp2;
			splitCurveByT([curve1 pt1],[curve1 pt2],[curve1 cp1],[curve1 cp2],mint,leftpt3,leftcp1,leftcp2,rightcp1,rightcp2);
			[curve1 setPt1:leftpt3];
			[curve1 setCp1:rightcp1];
			[curve1 setCp2:rightcp2];
		   }
	   }
	else																			//we will intersect with the tangent
	   {
		NSPoint npt;
		npt.x = curvept1.x + [curve1 startDirectionVector].x;
		npt.y = curvept1.y + [curve1 startDirectionVector].y;
		linesIntersect([line1 fromPt],[line1 toPt],npt,curvept1,intersectionPt);
		[line1 setToPt:intersectionPt];
		[additions addObject:[gLine gLineFrom:intersectionPt to:curvept1]];
	   }
   }

void adjustCurveAndLine(gCurve *curve1,gLine *line1,bool doingLeft,NSMutableArray* additions)
   {
	if ([line1 direction] == 0)
		return;
	if (NSEqualPoints([line1 fromPt],[line1 toPt]))
		return;
	NSPoint curveLastPt,curveLastPt2;
	[curve1 lastPoint:&curveLastPt secondLastPoint:&curveLastPt2];
	if (NSEqualPoints(curveLastPt,curveLastPt2))
		return;
	NSPoint intersectionPt;
	if (([line1 direction] > 0 && doingLeft) || ([line1 direction] < 0 && !doingLeft))		//we will intersect with the curve itself
	   {
		NSMutableArray *intersectPoints = [NSMutableArray arrayWithCapacity:10];
		NSMutableArray *os = [NSMutableArray arrayWithCapacity:10];
		NSMutableArray *ot = [NSMutableArray arrayWithCapacity:10];
		bool collinear;
		lineCurveIntersection([line1 fromPt],[line1 toPt],[curve1 pt1],[curve1 pt2],[curve1 cp1],[curve1 cp2],intersectPoints,os,ot,collinear,0.0,1.0,true);
		double maxt = -1.0;
		int maxind = -1;
		NSUInteger ct = [ot count];
		for (int i = 0;i < ct;i++)
		   {
			double t = [[ot objectAtIndex:i]doubleValue];
			if (t > maxt)
			   {
				maxt = t;
				maxind = i;
			   }
		   }
		if (maxind >= 0)
		   {
			intersectionPt = [[intersectPoints objectAtIndex:maxind]pointValue];
			[line1 setFromPt:intersectionPt];
			NSPoint leftpt3,leftcp1,leftcp2,rightcp1,rightcp2;
			splitCurveByT([curve1 pt1],[curve1 pt2],[curve1 cp1],[curve1 cp2],maxt,leftpt3,leftcp1,leftcp2,rightcp1,rightcp2);
			[curve1 setPt2:leftpt3];
			[curve1 setCp1:leftcp1];
			[curve1 setCp2:leftcp2];
		   }
	   }
	else																			//we will intersect with the tangent
	   {
		NSPoint npt;
		npt.x = curveLastPt.x + [curve1 endDirectionVector].x;
		npt.y = curveLastPt.y + [curve1 endDirectionVector].y;
		linesIntersect([line1 fromPt],[line1 toPt],curveLastPt,npt,intersectionPt);
		[additions addObject:[gLine gLineFrom:curveLastPt to:intersectionPt]];
		[line1 setFromPt:intersectionPt];
	   }
   }

void adjust2Curves(gCurve *curve1,gCurve *curve2,bool doingLeft,NSMutableArray* additions)
   {
	if ([curve2 direction] == 0)
		return;
	NSPoint curve1LastPt,curve1LastPt2,curve2FirstPt,curve2SecondPt;
	[curve1 lastPoint:&curve1LastPt secondLastPoint:&curve1LastPt2];
	if (NSEqualPoints(curve1LastPt,curve1LastPt2))
		return;
	[curve2 firstPoint:&curve2FirstPt secondPoint:&curve2SecondPt];
	if (NSEqualPoints(curve2FirstPt,curve2SecondPt))
		return;
	NSPoint intersectionPt;
	if (([curve2 direction] > 0 && doingLeft) || ([curve2 direction] < 0 && !doingLeft))		//actual curves will intersect
	   {
		NSMutableArray *intersectPoints = [NSMutableArray arrayWithCapacity:10];
		NSMutableArray *os = [NSMutableArray arrayWithCapacity:10];
		NSMutableArray *ot = [NSMutableArray arrayWithCapacity:10];
		bool collinear;
		curveCurveIntersection([curve1 pt1],[curve1 pt2],[curve1 cp1],[curve1 cp2],
							   [curve2 pt1],[curve2 pt2],[curve2 cp1],[curve2 cp2],intersectPoints,os,ot,collinear,0.0,1.0,0.0,1.0);
		double mint = 2.0;
		int minind = -1;
		NSUInteger ct = [ot count];
		for (int i = 0;i < ct;i++)
		   {
			double t = [[ot objectAtIndex:i]doubleValue];
			if (t < mint)
			   {
				mint = t;
				minind = i;
			   }
		   }
		if (minind >= 0)
		   {
			intersectionPt = [[intersectPoints objectAtIndex:minind]pointValue];
			NSPoint leftpt3,leftcp1,leftcp2,rightcp1,rightcp2;
			splitCurveByT([curve1 pt1],[curve1 pt2],[curve1 cp1],[curve1 cp2],[[os objectAtIndex:minind]doubleValue],leftpt3,leftcp1,leftcp2,rightcp1,rightcp2);
			[curve1 setPt2:leftpt3];
			[curve1 setCp1:leftcp1];
			[curve1 setCp2:leftcp2];
			splitCurveByT([curve2 pt1],[curve2 pt2],[curve2 cp1],[curve2 cp2],[[ot objectAtIndex:minind]doubleValue],leftpt3,leftcp1,leftcp2,rightcp1,rightcp2);
			[curve2 setPt1:leftpt3];
			[curve2 setCp1:rightcp1];
			[curve2 setCp2:rightcp2];
		   }
	   }
	else																			//we will intersect with the tangent
	   {
		NSPoint npt1,npt2;
		npt1.x = curve1LastPt.x - [curve1 endDirectionVector].x;
		npt1.y = curve1LastPt.y - [curve1 endDirectionVector].y;
		npt2.x = curve2FirstPt.x - [curve2 startDirectionVector].x;
		npt2.y = curve2FirstPt.y - [curve2 startDirectionVector].y;
		NSPoint intersectPoints[5];
		double os[5], ot[5];
		int noIntersections = linesIntersect(npt1,curve1LastPt,curve2FirstPt,npt2,intersectPoints,os,ot);
		if (noIntersections == 1 && os[0] >= 1.0)
		   {
			[additions addObject:[gLine gLineFrom:curve1LastPt to:intersectPoints[0]]];
			[additions addObject:[gLine gLineFrom:intersectPoints[0] to:curve2FirstPt]];
			return;
		   }
		[additions addObject:[gLine gLineFrom:curve1LastPt to:curve2FirstPt]];
	   }
   }

void adjustLines(NSMutableArray *lines,BOOL closed,bool doingLeft)
   {
	unsigned i,j;
	NSUInteger count = [lines count];
	if (count < 2)
		return;
	NSMutableArray *additions = [NSMutableArray arrayWithCapacity:2];
	for (i = 0;i < [lines count];i++)
	   {
		[additions removeAllObjects];
		j = i + 1;
		if (j == [lines count] && closed)
			j = 0;
		if (j < [lines count])
		   {
			id obji = [lines objectAtIndex:i];
			id objj = [lines objectAtIndex:j];
			if ([obji isKindOfClass:[gLine class]])
				if ([objj isKindOfClass:[gLine class]])
					adjust2lines(obji,objj);
				else
					adjustLineAndCurve(obji,objj,doingLeft,additions);
			else
				if ([objj isKindOfClass:[gLine class]])
					adjustCurveAndLine(obji,objj,doingLeft,additions);
				else
					adjust2Curves(obji,objj,doingLeft,additions);
			for (unsigned k = 0;k < [additions count];k++)
				[lines insertObject:[additions objectAtIndex:k]atIndex:(++i)];
		   }
	   }
   }

#define AREA_THRESH 0.00001

int lineCurveIntersection(NSPoint lpt1,NSPoint lpt2,NSPoint pt0,NSPoint pt3,NSPoint cp1,NSPoint cp2,
	NSMutableArray* intersectPoints,NSMutableArray* os,NSMutableArray* ot, 
	bool &collinear,double leftT,double rightT,bool includeRightHandPoint)
   {
//	double areaHull = areaConvexQuadrilateral(pt0,pt3,cp1,cp2);
//	double areaHull = fabs(Area2(pt0,cp1,pt3)) + fabs(Area2(pt0,cp2,pt3));
//	if (areaHull < AREA_THRESH)
	if (flatness(pt0,pt3,cp1,cp2) < FLAT_THRESHOLD)
	   {
		NSPoint ip[5];
		double is[5],it[5];
		int res;
		if ((res = lineAndSegmentIntersect(lpt1,lpt2,pt0,pt3,ip,is,it)) > -1)
		   {
			if (includeRightHandPoint || it[res] != 1.0)
			   {
				[intersectPoints addObject:[NSValue valueWithPoint:ip[res]]];
				[os addObject:[NSNumber numberWithDouble:is[res]]];
				[ot addObject:[NSNumber numberWithDouble:leftT + (rightT - leftT) * it[res]]];
			   }
		   }
	   }
	else if (lineAndSegmentIntersect(lpt1,lpt2,pt0,cp1) ||
		lineAndSegmentIntersect(lpt1,lpt2,cp1,cp2) ||
		lineAndSegmentIntersect(lpt1,lpt2,cp2,pt3) ||
		lineAndSegmentIntersect(lpt1,lpt2,pt3,pt0))
	   {
		NSPoint leftpt3,leftcp1,leftcp2,rightcp1,rightcp2;
		splitCurveByT(pt0,pt3,cp1,cp2,0.5,leftpt3,leftcp1,leftcp2,rightcp1,rightcp2);
		double midT = (leftT + rightT)/2.0;
		lineCurveIntersection(lpt1,lpt2,pt0,leftpt3,leftcp1,leftcp2,intersectPoints,os,ot,collinear,leftT,midT,false);
		lineCurveIntersection(lpt1,lpt2,leftpt3,pt3,rightcp1,rightcp2,intersectPoints,os,ot,collinear,midT,rightT,includeRightHandPoint);
	   }
	return (int)[intersectPoints count];
   }

bool point_curve(NSPoint pt0,NSPoint pt3,NSPoint cp1,NSPoint cp2)
   {
	return (NSEqualPoints(pt0,pt3) &&
			NSEqualPoints(pt0,cp1) &&
			NSEqualPoints(pt0,cp2));		
   }

int curveCurveIntersection(NSPoint c1pt0,NSPoint c1pt3,NSPoint c1cp1,NSPoint c1cp2,
							NSPoint c2pt0,NSPoint c2pt3,NSPoint c2cp1,NSPoint c2cp2,
							NSMutableArray* intersectPoints,NSMutableArray* os,NSMutableArray* ot,bool &collinear,
							double leftS,double rightS,double leftT,double rightT)
   {
	if (!quadsIntersect(c1pt0,c1pt3,c1cp2,c1cp1,c2pt0,c2pt3,c2cp2,c2cp1))
		return 0;
	if (point_curve(c1pt0,c1pt3,c1cp1,c1cp2) || point_curve(c2pt0,c2pt3,c2cp1,c2cp2))
		return 0;
	bool smallC1 = flatness(c1pt0,c1pt3,c1cp1,c1cp2) < FLAT_THRESHOLD;
	bool smallC2 = flatness(c2pt0,c2pt3,c2cp1,c2cp2) < FLAT_THRESHOLD;
	if (smallC1 && smallC2)
	   {
		if (NSEqualPoints(c1pt0,c2pt0))
		   {
			[intersectPoints addObject:[NSValue valueWithPoint:c1pt0]];
			[os addObject:[NSNumber numberWithDouble:leftS]];
			[ot addObject:[NSNumber numberWithDouble:leftT]];			
			return (int)[intersectPoints count];
		   }
		if (NSEqualPoints(c1pt0,c2pt3))
		   {
			[intersectPoints addObject:[NSValue valueWithPoint:c1pt0]];
			[os addObject:[NSNumber numberWithDouble:leftS]];
			[ot addObject:[NSNumber numberWithDouble:rightT]];			
			return (int)[intersectPoints count];
		   }
		if (NSEqualPoints(c1pt3,c2pt0))
		   {
			[intersectPoints addObject:[NSValue valueWithPoint:c1pt3]];
			[os addObject:[NSNumber numberWithDouble:rightS]];
			[ot addObject:[NSNumber numberWithDouble:leftT]];			
			return (int)[intersectPoints count];
		   }
		if (NSEqualPoints(c1pt3,c2pt3))
		   {
			[intersectPoints addObject:[NSValue valueWithPoint:c1pt3]];
			[os addObject:[NSNumber numberWithDouble:rightS]];
			[ot addObject:[NSNumber numberWithDouble:rightT]];			
			return (int)[intersectPoints count];
		   }
		NSPoint ip[5];
		double is[5],it[5];
		int res;
		if ((res = lineAndSegmentIntersect(c1pt0,c1pt3,c2pt0,c2pt3,ip,is,it)) > -1)
		   {
			[intersectPoints addObject:[NSValue valueWithPoint:ip[res]]];
			[os addObject:[NSNumber numberWithDouble:leftS + (rightS - leftS) * is[res]]];
			[ot addObject:[NSNumber numberWithDouble:leftT + (rightT - leftT) * it[res]]];
		   }
		return (int)[intersectPoints count];
	   }
	if (smallC1)
	   {
		NSPoint leftpt3,leftcp1,leftcp2,rightcp1,rightcp2;
		splitCurveByT(c2pt0,c2pt3,c2cp1,c2cp2,0.5,leftpt3,leftcp1,leftcp2,rightcp1,rightcp2);
		double midT = (leftT + rightT)/2.0;
		curveCurveIntersection(c1pt0,c1pt3,c1cp1,c1cp2,c2pt0,leftpt3,leftcp1,leftcp2,intersectPoints,os,ot,collinear,leftS,rightS,leftT,midT);
		curveCurveIntersection(c1pt0,c1pt3,c1cp1,c1cp2,leftpt3,c2pt3,rightcp1,rightcp2,intersectPoints,os,ot,collinear,leftS,rightS,midT,rightT);
	   }
	else if (smallC2)
	   {
		NSPoint leftpt3,leftcp1,leftcp2,rightcp1,rightcp2;
		splitCurveByT(c1pt0,c1pt3,c1cp1,c1cp2,0.5,leftpt3,leftcp1,leftcp2,rightcp1,rightcp2);
		double midS = (leftS + rightS)/2.0;
		curveCurveIntersection(c1pt0,leftpt3,leftcp1,leftcp2,c2pt0,c2pt3,c2cp1,c2cp2,intersectPoints,os,ot,collinear,leftS,midS,leftT,rightT);
		curveCurveIntersection(leftpt3,c1pt3,rightcp1,rightcp2,c2pt0,c2pt3,c2cp1,c2cp2,intersectPoints,os,ot,collinear,midS,rightS,leftT,rightT);
	   }
	else
	   {
		NSPoint left1pt3,left1cp1,left1cp2,right1cp1,right1cp2;
		NSPoint left2pt3,left2cp1,left2cp2,right2cp1,right2cp2;
		splitCurveByT(c1pt0,c1pt3,c1cp1,c1cp2,0.5,left1pt3,left1cp1,left1cp2,right1cp1,right1cp2);
		splitCurveByT(c2pt0,c2pt3,c2cp1,c2cp2,0.5,left2pt3,left2cp1,left2cp2,right2cp1,right2cp2);
		double midS = (leftS + rightS)/2.0;
		double midT = (leftT + rightT)/2.0;
		curveCurveIntersection(c1pt0,left1pt3,left1cp1,left1cp2,c2pt0,left2pt3,left2cp1,left2cp2,intersectPoints,os,ot,collinear,leftS,midS,leftT,midT);
		curveCurveIntersection(left1pt3,c1pt3,right1cp1,right1cp2,c2pt0,left2pt3,left2cp1,left2cp2,intersectPoints,os,ot,collinear,midS,rightS,leftT,midT);
		curveCurveIntersection(c1pt0,left1pt3,left1cp1,left1cp2,left2pt3,c2pt3,right2cp1,right2cp2,intersectPoints,os,ot,collinear,leftS,midS,midT,rightT);
		curveCurveIntersection(left1pt3,c1pt3,right1cp1,right1cp2,left2pt3,c2pt3,right2cp1,right2cp2,intersectPoints,os,ot,collinear,midS,rightS,midT,rightT);
	   }
	return (int)[intersectPoints count];
   }

double Area2(NSPoint a,NSPoint b,NSPoint c)
												//
   {
	return ((b.x - a.x) * (c.y - a.y) - (c.x - a.x) * (b.y - a.y));
   }

int SignArea2(NSPoint a,NSPoint b,NSPoint c)
												// -1, 0, or 1 depending on sign of Area2
   {
	double res =  Area2(a,b,c);
	if (res == 0.0)
		return 0;
	else if (res < 0.0)
		return -1;
	else
		return 1;
   }

bool collinear(NSPoint a,NSPoint b,NSPoint c)
												//returns true if a, b, and c are collinear
   {
	return Area2(a,b,c) == 0.0;
   }

double collinearS(NSPoint a,NSPoint b,NSPoint c)
												//returns s for point c on line ab
   {
	if (a.x == b.x)
		return (c.y - a.y) / (b.y - a.y);
	else
		return (c.x - a.x) / (b.x - a.x);
   }

int getCollinearIntersectPoints(NSPoint a,NSPoint b,NSPoint c,NSPoint d,NSPoint intersectPoints[],double os[],double ot[])
   {
	int i = 0;
	intersectPoints[i] = a;
	os[i] = 0.0;
	ot[i++] = collinearS(c,d,a);
	intersectPoints[i] = b;
	os[i] = 1.0;
	ot[i++] = collinearS(c,d,b);
	intersectPoints[i] = c;
	os[i] = collinearS(a,b,c);
	ot[i++] = 0.0;
	intersectPoints[i] = d;
	os[i] = collinearS(a,b,d);
	ot[i++] = 1.0;
	return i;
   }

int checkEndPointsIntersect(NSPoint a,NSPoint b,NSPoint c,NSPoint d,NSPoint intersectPoints[],double os[],double ot[])
   {
	if (NSEqualPoints(a,c))
	   {
		intersectPoints[0] = a;
		os[0] = 0.0;
		ot[0] = 0.0;
		return 1;
	   }
	if (NSEqualPoints(b,c))
	   {
		intersectPoints[0] = b;
		os[0] = 1.0;
		ot[0] = 0.0;
		return 1;
	   }
	if (NSEqualPoints(a,d))
	   {
		intersectPoints[0] = a;
		os[0] = 0.0;
		ot[0] = 1.0;
		return 1;
	   }
	if (NSEqualPoints(b,d))
	   {
		intersectPoints[0] = b;
		os[0] = 1.0;
		ot[0] = 1.0;
		return 1;
	   }
	return 0;
   }
   
int linesIntersect(NSPoint a,NSPoint b,NSPoint c,NSPoint d,NSPoint intersectPoints[],double os[],double ot[])
												//returns no of intersections of line ab with line cd
												//if actual segment intersection, s will be >=0 and <=1
   {
	double num,denom,s,t;
	denom = a.x * (d.y - c.y) +
			b.x * (c.y - d.y) +
			d.x * (b.y - a.y) +
			c.x * (a.y - b.y);
	if (denom == 0.0)							// lines are parallel
		if (collinear(a,b,c))
		   {
			int ct = getCollinearIntersectPoints(a,b,c,d,intersectPoints,os,ot);
			return ct;
		   }
		else
			return 0;
	if (checkEndPointsIntersect(a,b,c,d,intersectPoints,os,ot))		//required because of rounding errors
		return 1;
	num =   a.x * (d.y - c.y) +
			c.x * (a.y - d.y) +
			d.x * (c.y - a.y);
//	if (num == 0.0 || num == denom)
	s = num/denom;
	num =   -(a.x * (c.y - b.y) +
			b.x * (a.y - c.y) +
			c.x * (b.y - a.y));
//	if (num == 0.0 || num == denom)
	t = num/denom;
	intersectPoints[0].x = a.x + s * (b.x - a.x);
	intersectPoints[0].y = a.y + s * (b.y - a.y);
	os[0] = s;
	ot[0] = t;
	return 1;
   }

bool lineSegmentsIntersect(NSPoint a,NSPoint b,NSPoint c,NSPoint d)
   {
	NSPoint dummyPts[5];
	double dummyS[5],dummyT[5];
	int ct = linesIntersect(a,b,c,d,dummyPts,dummyS,dummyT);
	for (int i = 0;i < ct;i++)
		if (dummyS[i] >= 0.0 && dummyS[i] <= 1.0 && dummyT[i] >= 0.0 && dummyT[i] <= 1.0)
			return YES;
	return NO;
   }

bool linesIntersect(NSPoint a,NSPoint b,NSPoint c,NSPoint d)
   {
	NSPoint dummyPts[5];
	double dummyS[5],dummyT[5];
	int ct = linesIntersect(a,b,c,d,dummyPts,dummyS,dummyT);
	return ct > 0;
   }

bool lineAndSegmentIntersect(NSPoint la,NSPoint lb,NSPoint sc,NSPoint sd)
   {
	NSPoint dummyPts[5];
	double dummyS[5],dummyT[5];
	int ct = linesIntersect(la,lb,sc,sd,dummyPts,dummyS,dummyT);
	for (int i = 0;i < ct;i++)
		if (dummyT[i] >= 0.0 && dummyT[i] <= 1.0)
			return YES;
	return NO;
   }

int lineAndSegmentIntersect(NSPoint la,NSPoint lb,NSPoint sc,NSPoint sd,NSPoint ip[],double s[],double t[])
   {
	int ct = linesIntersect(la,lb,sc,sd,ip,s,t);
	for (int i = 0;i < ct;i++)
		if (t[i] >= 0.0 && t[i] <= 1.0)
			return i;
	return -1;
   }

double areaTriangle(NSPoint a,NSPoint b,NSPoint c)
   {
	return (b.x - a.x) * (c.y - a.y) - (c.x - a.x) * (b.y - a.y);
   }

double areaConvexQuadrilateral(NSPoint a,NSPoint b,NSPoint c,NSPoint d)
   {
	return fabs(areaTriangle(a,b,c)) + fabs(areaTriangle(b,d,c));
   }

bool pointInConvexQuad(NSPoint pt,NSPoint a,NSPoint b,NSPoint c,NSPoint d)
   {
	int sgn = SignArea2(a,b,pt);
	if (sgn == 0)
		return true;
	if (SignArea2(b,c,pt) != sgn)
		return false;
	if (SignArea2(c,d,pt) != sgn)
		return false;
	if (SignArea2(d,a,pt) != sgn)
		return false;
	return true;
   }

bool quadsIntersect(NSPoint a1,NSPoint b1,NSPoint c1,NSPoint d1,NSPoint a2,NSPoint b2,NSPoint c2,NSPoint d2)
   {
	NSPoint q1[5],q2[5];
	q1[0] = q1[4] = a1;
	q1[1] = b1; q1[2] = c1; q1[3] = d1;
	q2[0] = q2[4] = a2;
	q2[1] = b2; q2[2] = c2; q2[3] = d2;
	for (int i = 0;i < 4;i++)
		for (int j = 0;j < 4;j++)
			if (lineSegmentsIntersect(q1[i],q1[i+1],q2[j],q2[j+1]))
				return true;
	return pointInConvexQuad(a2,a1,b1,c1,d1);
   }

float PolygonArea(NSPoint *points,int count)
{
	float area = 0.0;
	for (int i = 0;i < count;i++)
	{
		int j = (i + 1)%count;
		area += ((points[i].x * points[j].y)-(points[j].x*points[i].y));
	}
	return area / 2.0;
}

NSPoint Centroid(NSPoint *points,int count)
{
	float xsum = 0;
	float ysum = 0;
	float area = PolygonArea(points,count);
	for (int i = 0;i < count;i++)
	{
		int j = (i + 1)%count;
		float factor = (points[i].x * points[j].y - points[j].x * points[i].y);
		xsum += ((points[i].x + points[j].x)*factor);
		ysum += ((points[i].y + points[j].y)*factor);
	}
	return NSMakePoint(xsum/(6.0*area),ysum/(6.0*area));
}

NSPoint LocationForRect(float x,float y,NSRect r)
{
	NSPoint pt;
	pt.x = r.origin.x + x * r.size.width;
	pt.y = r.origin.y + y * r.size.height;
	return pt;
}

NSPoint RelativePointInRect(float x,float y,NSRect r)
{
	NSPoint pt;
	pt.x = (x - r.origin.x) / r.size.width;
	pt.y = (y - r.origin.y) / r.size.height;
	return pt;
}

NSPoint InvertedPoint(NSPoint pt,float docHeight)
{
	pt.y = docHeight - pt.y;
	return pt;
}

NSRect InvertedRect(NSRect r,float docHeight)
{
	r.origin.y = docHeight - (r.origin.y + r.size.height);
	return r;
}

CGPoint bezease(float t)
{
    CGPoint p0 = CGPointZero;
    CGPoint c0 = CGPointMake(0.42, 0.0);
    CGPoint c1 = CGPointMake(0.58, 1.0);
    CGPoint p1 = CGPointMake(1.0, 1.0);
    CGFloat tprime = 1.0 - t;
    CGFloat tprime2 = tprime * tprime;
    CGFloat t2 = t * t;
    CGPoint f0 = CGPointMake(p0.x * tprime * tprime2, p0.y * tprime * tprime2);
    CGPoint fc0 = CGPointMake(c0.x * tprime2 * 3 * t,c0.y * tprime2 * 3 * t);
    CGPoint fc1 = CGPointMake(c1.x * tprime * t2 * 3,c1.y * tprime * t2 * 3);
    CGPoint f1 = CGPointMake(t2 * t * p1.x,t2 * t * p1.y);
    return CGPointMake(f0.x+fc0.x+fc1.x+f1.x,f0.y+fc0.y+fc1.y+f1.y);
	
}

CGFloat bezef(float t)
{
    return clamp01(bezease(clamp01(t)).y);
}

float clamp01(float t)
{
    if (t < 0.0)
        return 0.0;
    if (t > 1.0)
        return 1.0;
    return t;
}

float interpolateVal(float start,float end,float t)
{
    return start + (end - start) * t;
}

CGFloat FloatOrPercentage(NSString *str)
{
	str = [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if ([str length] == 0)
		return 0;
	BOOL ispc = NO;
	if ([[str substringFromIndex:[str length]-1]isEqualToString:@"%"])
	{
		ispc = YES;
		str = [str substringToIndex:[str length]-1];
	}
	CGFloat f = [str floatValue];
	if (ispc)
		f = f / 100.0;
	return f;
}
