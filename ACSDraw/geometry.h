/*
 *  geometry.h
 *  ACSDraw
 *
 *  Created by alan on Sun Mar 14 2004.
 *  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
 *
 */

#import <Cocoa/Cocoa.h>
#import "gCurve.h"
#import "gLine.h"
NSRect RectFromPoint(NSPoint pt,float padding,float magnification);
NSPoint top_left(NSRect r);
NSPoint bottom_left(NSRect r);
NSPoint top_right(NSRect r);
NSPoint bottom_right(NSRect r);
void quarter_rects(NSRect inRect,NSRect &blRect,NSRect &tlRect,NSRect &trRect,NSRect &brRect);
NSRect rectFromPoints(NSPoint pt1,NSPoint pt2);
NSRect expandRectToPoint(NSRect r,NSPoint p);
BOOL lineInRect(NSRect r,NSPoint p0,NSPoint p1);
NSPoint midPoint(NSPoint p0,NSPoint p1);
NSPoint tPointAlongLine(CGFloat t,NSPoint p0,NSPoint p1);
CGFloat squaredDistance(NSPoint p0,NSPoint p1);
CGFloat pointDistance(NSPoint p0,NSPoint p1);

NSPoint diff_points(NSPoint pt2,NSPoint pt1);
NSSize point_offset(NSPoint pt2,NSPoint pt1);
NSPoint offset_point(NSPoint pt,NSPoint offset);
NSPoint offset_point(NSPoint pt,NSSize offset);
NSSize neg_size(NSSize sz);
CGFloat dot_product(NSPoint pt1,NSPoint pt2);
NSPoint lperp(NSPoint d);						//returns difference vector perpendicular to d (left-hand)
NSPoint rperp(NSPoint d);						//returns difference vector perpendicular to d (right-hand)
CGFloat dlen(NSPoint d);							//length of difference vector
NSPoint vecMultiply(NSPoint vec,float factor);

CGFloat pointDistanceFromLineSegment(NSPoint linePt0,NSPoint linePt1,NSPoint testPoint,
	                       CGFloat &t,NSPoint &hitPointOnLine);
BOOL testLineSegmentHit(NSPoint linePt0,NSPoint linePt1,NSPoint testPoint,
	                       CGFloat &t,NSPoint &hitPointOnLine,CGFloat &distance,CGFloat threshold);
BOOL testLineSegmentHit(NSPoint linePt0,NSPoint linePt1,NSPoint testPoint,CGFloat threshold);
BOOL testCurveHit(NSPoint startPt,NSPoint endPt,NSPoint controlPt1,NSPoint controlPt2,NSPoint testPoint,
				CGFloat &t,NSPoint &hitPointOnCurve,CGFloat &distance,CGFloat threshold,CGFloat dist2,CGFloat leftT,CGFloat rightT);
void splitCurveByT(NSPoint startPt,NSPoint endPt,NSPoint controlPt1,NSPoint controlPt2,CGFloat t,
					NSPoint &c1EndPt,NSPoint &c1CP1,NSPoint &c1CP2,
					NSPoint &c2CP1,NSPoint &c2CP2);
BOOL nearestPointOnCurve(NSPoint startPt,NSPoint endPt,NSPoint controlPt1,NSPoint controlPt2,NSPoint testPoint,
				CGFloat &t,NSPoint &hitPointOnCurve,CGFloat &distance,CGFloat threshold,CGFloat dist2,CGFloat leftT,CGFloat rightT);
void outlineLine(gLine *inLine,float strokeWidth,NSMutableArray *leftLines,NSMutableArray *rightLines);
void outlineCurve(gCurve *inCurve,NSMutableArray *leftLines,NSMutableArray *rightLines,CGFloat strokeWidth);
void adjustLines(NSMutableArray *lines,BOOL closed,bool doingLeft);
void bzNormal(gCurve *inCurve,CGFloat t,NSPoint &b30,NSPoint &d);
void bzTangent(gCurve *inCurve,CGFloat t,NSPoint &b30,NSPoint &d);
#define AREA_THRESH 0.00001

int lineCurveIntersection(NSPoint lpt1,NSPoint lpt2,NSPoint pt0,NSPoint pt3,NSPoint cp1,NSPoint cp2,
	NSMutableArray* intersectPoints,NSMutableArray* os,NSMutableArray* ot, 
	bool &collinear,double leftT,double rightT,bool includeRightHandPoint);
int curveCurveIntersection(NSPoint c1pt0,NSPoint c1pt3,NSPoint c1cp1,NSPoint c1cp2,
							NSPoint c2pt0,NSPoint c2pt3,NSPoint c2cp1,NSPoint c2cp2,
							NSMutableArray* intersectPoints,NSMutableArray* os,NSMutableArray* ot,bool &collinear,
							double leftS,double rightS,double leftT,double rightT);
double Area2(NSPoint a,NSPoint b,NSPoint c);
int SignArea2(NSPoint a,NSPoint b,NSPoint c);
bool collinear(NSPoint a,NSPoint b,NSPoint c);
double collinearS(NSPoint a,NSPoint b,NSPoint c);
int getCollinearIntersectPoints(NSPoint a,NSPoint b,NSPoint c,NSPoint d,NSPoint intersectPoints[],double os[],double ot[]);
void getXorYC(CGFloat x1,CGFloat x2,CGFloat xi,CGFloat xj,CGFloat t,CGFloat &rxc1,CGFloat &rxc2);
int linesIntersect(NSPoint a,NSPoint b,NSPoint c,NSPoint d,NSPoint intersectPoints[],double os[],double ot[]);
bool lineSegmentsIntersect(NSPoint a,NSPoint b,NSPoint c,NSPoint d);
bool linesIntersect(NSPoint a,NSPoint b,NSPoint c,NSPoint d);
bool lineAndSegmentIntersect(NSPoint la,NSPoint lb,NSPoint sc,NSPoint sd);
int lineAndSegmentIntersect(NSPoint la,NSPoint lb,NSPoint sc,NSPoint sd,NSPoint ip[],double s[],double t[]);
double areaTriangle(NSPoint a,NSPoint b,NSPoint c);
double areaConvexQuadrilateral(NSPoint a,NSPoint b,NSPoint c,NSPoint d);
bool quadsIntersect(NSPoint a1,NSPoint b1,NSPoint c1,NSPoint d1,NSPoint a2,NSPoint b2,NSPoint c2,NSPoint d2);
void splitCurveByT(NSPoint startPt,NSPoint endPt,NSPoint controlPt1,NSPoint controlPt2,double t,
					NSPoint &c1EndPt,NSPoint &c1CP1,NSPoint &c1CP2,
					NSPoint &c2CP1,NSPoint &c2CP2);
double arcLength(NSPoint pt00,NSPoint pt01,NSPoint pt02,NSPoint pt03,int steps,double minT,double maxT);
double tForS(NSPoint pt00,NSPoint pt01,NSPoint pt02,NSPoint pt03,int steps,double s,double arclength);
double sForT(gCurve *inCurve,CGFloat t);

CGFloat squaredPointDistanceFromLineSegment(NSPoint linePt0,NSPoint linePt1,NSPoint testPoint,
										  CGFloat &t,NSPoint &hitPointOnLine);
CGFloat flatness(NSPoint centrepoint,NSPoint pt0,NSPoint pt1);
CGFloat flatness(NSPoint startPt,NSPoint endPt,NSPoint controlPt1,NSPoint controlPt2);
NSRect curveBounds(NSPoint p1,NSPoint p2,NSPoint p3,NSPoint p4);
NSArray *splitCurveByT(gCurve *inCurve,CGFloat t);
double bezfunc(double t,double c0,double c1,double c2,double c3,double c4);
double simpson(double a,double b,int maxSteps,double c0,double c1,double c2,double c3,double c4);
BOOL lineIntersectsWithBoundingBox(NSPoint linePt1,NSPoint linePt2,NSRect bBox);	// Wrong!
BOOL lineSegmentsIntersect(NSPoint a,NSPoint b,NSPoint c,NSPoint d,NSPoint &intersectPoint);
BOOL linesIntersect(NSPoint a,NSPoint b,NSPoint c,NSPoint d,NSPoint &intersectPoint);
void getOutlineLine(gLine *inLine,NSMutableArray *list,float offset);
BOOL curveError(gCurve *newCurve,gCurve *originalCurve,CGFloat offset,CGFloat errorThreshold);
void getOutlineCurve(gCurve *inCurve,NSMutableArray *curveList,CGFloat offset);
void adjust2lines(gLine *line1,gLine *line2);
void adjustLineAndCurve(gLine *line1,gCurve *curve1,bool doingLeft,NSMutableArray* additions);
void adjustCurveAndLine(gCurve *curve1,gLine *line1,bool doingLeft,NSMutableArray* additions);
void adjust2Curves(gCurve *curve1,gCurve *curve2,bool doingLeft,NSMutableArray* additions);
bool point_curve(NSPoint pt0,NSPoint pt3,NSPoint cp1,NSPoint cp2);
int checkEndPointsIntersect(NSPoint a,NSPoint b,NSPoint c,NSPoint d,NSPoint intersectPoints[],double os[],double ot[]);
bool pointInConvexQuad(NSPoint pt,NSPoint a,NSPoint b,NSPoint c,NSPoint d);
float PolygonArea(NSPoint *points,int count);
NSPoint Centroid(NSPoint *points,int count);
NSPoint LocationForRect(float x,float y,NSRect r);
CGPoint bezease(float t);
CGFloat bezef(float t);
float clamp01(float t);
float interpolateVal(float start,float end,float t);
NSPoint RelativePointInRect(float x,float y,NSRect r);
NSPoint InvertedPoint(NSPoint pt,float docHeight);
NSRect InvertedRect(NSRect r,float docHeight);
CGFloat FloatOrPercentage(NSString *str);


