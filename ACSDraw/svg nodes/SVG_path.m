//
//  SVG_path.m
//  Vectorius
//
//  Created by Alan Smith on 07/08/2020.
//  Copyright © 2020 Alan Smith. All rights reserved.
//

#import "SVG_path.h"

static NSCharacterSet *svgPathDelimCharacterSet()
{
    static NSMutableCharacterSet *charset = nil;
    if (charset == nil)
    {
        charset = [[NSCharacterSet whitespaceAndNewlineCharacterSet]mutableCopyWithZone:nil];
        [charset addCharactersInString:@","];
    }
    return charset;
}

static NSCharacterSet *svgFloatCharacterSet()
{
    static NSMutableCharacterSet *charset = nil;
    if (charset == nil)
    {
        charset = [[NSCharacterSet decimalDigitCharacterSet]mutableCopyWithZone:nil];
        [charset addCharactersInString:@".e"];
    }
    return charset;
}

static NSCharacterSet *svgCommandCharacterSet()
{
    static NSCharacterSet *charset = nil;
    if (charset == nil)
    {
        charset = [NSCharacterSet characterSetWithCharactersInString:@"zZMmLlHhVvCcSsQqTtAa"];
    }
    return charset;
}

static int skipdelims(NSString *str,int idx)
{
    NSCharacterSet *charset = svgPathDelimCharacterSet();
    while (idx < [str length])
    {
        unichar uc = [str characterAtIndex:idx];
        if (![charset characterIsMember:uc])
            return idx;
        idx++;
    }
    return idx;
}

static float getFloat(NSString* str,int *i)
{
    int idx = *i;
    NSMutableString *rstr = [[NSMutableString alloc]init];
    unichar lastChar = 0;
    idx = skipdelims(str, idx);
    if (idx < [str length])
    {
        if ([[str substringWithRange:NSMakeRange(idx, 1)]isEqualToString:@"-"])
        {
            idx++;
            [rstr appendString:@"-"];
        }
    }
    while (idx < [str length])
    {
        unichar uc = [str characterAtIndex:idx];
        if (!([svgFloatCharacterSet() characterIsMember:uc] || (uc == '-' && lastChar == 'e')))
            break;
        lastChar = uc;
        [rstr appendString:[str substringWithRange:NSMakeRange(idx, 1)]];
        idx++;
    }
    *i = idx;
    return [rstr floatValue];
}

BOOL stringContainsChar(NSString* s,unichar uc)
{
    NSString *str = [NSString stringWithCharacters:&uc length:1];
    NSRange r = [s rangeOfString:str];
    return r.length > 0;
}

NSBezierPath* BezierPathFromSVGPath(NSString *str)
{
    NSBezierPath *path = [NSBezierPath bezierPath];
    int idx = 0;
    idx = skipdelims(str,idx);
    float currx = 0.0,curry = 0.0,cx1,cy1,cx2,cy2,dx,dy,qx,qy;
    float rx,ry,xrot;
    int largearcflag,sweepflag;

    unichar implicitCommand = 'M',lastCommand=0,uc=0;
    NSPoint lastcurvepoint = NSZeroPoint;
    while (idx < [str length])
    {
        lastCommand = uc;
        uc = [str characterAtIndex:idx];
        if ([svgCommandCharacterSet() characterIsMember:uc])
            idx++;
        else
            uc = implicitCommand;
        switch (uc)
        {
            case 'M':
                currx = getFloat(str,&idx);
                curry = getFloat(str,&idx);
                [path moveToPoint:NSMakePoint(currx, curry)];
                implicitCommand = 'L';
                lastcurvepoint = NSZeroPoint;
                break;
            case 'm':
                currx += getFloat(str,&idx);
                curry += getFloat(str,&idx);
                [path moveToPoint:NSMakePoint(currx, curry)];
                implicitCommand = 'l';
                lastcurvepoint = NSZeroPoint;
                break;
            case 'L':
                currx = getFloat(str,&idx);
                curry = getFloat(str,&idx);
                [path lineToPoint:NSMakePoint(currx, curry)];
                lastcurvepoint = NSZeroPoint;
                implicitCommand = 'L';
                break;
            case 'l':
                currx += getFloat(str,&idx);
                curry += getFloat(str,&idx);
                [path lineToPoint:NSMakePoint(currx, curry)];
                implicitCommand = 'l';
                lastcurvepoint = NSZeroPoint;
                break;
            case 'H':
                currx = getFloat(str,&idx);
                [path lineToPoint:NSMakePoint(currx, curry)];
                implicitCommand = 'H';
                break;
            case 'h':
                currx += getFloat(str,&idx);
                [path lineToPoint:NSMakePoint(currx, curry)];
                implicitCommand = 'h';
                lastcurvepoint = NSZeroPoint;
                break;
            case 'V':
                curry = getFloat(str,&idx);
                [path lineToPoint:NSMakePoint(currx, curry)];
                implicitCommand = 'V';
                lastcurvepoint = NSZeroPoint;
                break;
            case 'v':
                curry += getFloat(str,&idx);
                [path lineToPoint:NSMakePoint(currx, curry)];
                implicitCommand = 'v';
                lastcurvepoint = NSZeroPoint;
                break;
            case 'C':
                cx1 = getFloat(str,&idx);
                cy1 = getFloat(str,&idx);
                cx2 = getFloat(str,&idx);
                cy2 = getFloat(str,&idx);
                lastcurvepoint = NSMakePoint(cx2,cy2);
                currx = getFloat(str,&idx);
                curry = getFloat(str,&idx);
                [path curveToPoint:NSMakePoint(currx, curry) controlPoint1:NSMakePoint(cx1, cy1) controlPoint2:NSMakePoint(cx2, cy2)];
                implicitCommand = 'C';
                break;
            case 'c':
                cx1 = currx + getFloat(str,&idx);
                cy1 = curry + getFloat(str,&idx);
                cx2 = currx + getFloat(str,&idx);
                cy2 = curry + getFloat(str,&idx);
                lastcurvepoint = NSMakePoint(cx2,cy2);
                currx += getFloat(str,&idx);
                curry += getFloat(str,&idx);
                [path curveToPoint:NSMakePoint(currx, curry) controlPoint1:NSMakePoint(cx1, cy1) controlPoint2:NSMakePoint(cx2, cy2)];
                implicitCommand = 'c';
                break;
            case 'S':
                if (! stringContainsChar(@"CcSs",lastCommand))
                    lastcurvepoint = NSZeroPoint;
                dx = currx - lastcurvepoint.x;
                dy = curry - lastcurvepoint.y;
                cx1 = currx + dx;
                cy1 = curry + dy;
                cx2 = getFloat(str,&idx);
                cy2 = getFloat(str,&idx);
                currx = getFloat(str,&idx);
                curry = getFloat(str,&idx);
                [path curveToPoint:NSMakePoint(currx, curry) controlPoint1:NSMakePoint(cx1, cy1) controlPoint2:NSMakePoint(cx2, cy2)];
                lastcurvepoint = NSMakePoint(cx2,cy2);
                implicitCommand = 'S';
                break;
            case 's':
                if (! stringContainsChar(@"CcSs",lastCommand))
                    lastcurvepoint = NSZeroPoint;
                dx = currx - lastcurvepoint.x;
                dy = curry - lastcurvepoint.y;
                cx1 = currx + dx;
                cy1 = curry + dy;
                cx2 = currx + getFloat(str,&idx);
                cy2 = curry + getFloat(str,&idx);
                currx += getFloat(str,&idx);
                curry += getFloat(str,&idx);
                [path curveToPoint:NSMakePoint(currx, curry) controlPoint1:NSMakePoint(cx1, cy1) controlPoint2:NSMakePoint(cx2, cy2)];
                lastcurvepoint = NSMakePoint(cx2,cy2);
                implicitCommand = 's';
                break;
            case 'Q':
                qx = getFloat(str,&idx);
                qy = getFloat(str,&idx);
                cx1 = currx + (2.0 / 3.0 * (qx - currx));
                cy1 = curry + (2.0 / 3.0 * (qy - curry));
                currx = getFloat(str,&idx);
                curry = getFloat(str,&idx);
                cx2 = currx + (2.0 / 3.0 * (qx - currx));
                cy2 = curry + (2.0 / 3.0 * (qy - curry));
                lastcurvepoint = NSMakePoint(qx,qy);
                [path curveToPoint:NSMakePoint(currx, curry) controlPoint1:NSMakePoint(cx1, cy1) controlPoint2:NSMakePoint(cx2, cy2)];
                implicitCommand = 'Q';
                break;
            case 'q':
                qx = currx + getFloat(str,&idx);
                qy = curry + getFloat(str,&idx);
                cx1 = currx + (2.0 / 3.0 * (qx - currx));
                cy1 = curry + (2.0 / 3.0 * (qy - curry));
                currx += getFloat(str,&idx);
                curry += getFloat(str,&idx);
                cx2 = currx + (2.0 / 3.0 * (qx - currx));
                cy2 = curry + (2.0 / 3.0 * (qy - curry));
                lastcurvepoint = NSMakePoint(qx,qy);
                [path curveToPoint:NSMakePoint(currx, curry) controlPoint1:NSMakePoint(cx1, cy1) controlPoint2:NSMakePoint(cx2, cy2)];
                implicitCommand = 'q';
                break;
            case 'T':
                if (! stringContainsChar(@"QqTt",lastCommand))
                    lastcurvepoint = NSZeroPoint;
                dx = currx - lastcurvepoint.x;
                dy = curry - lastcurvepoint.y;
                qx = currx + dx;
                qy = curry + dy;
                cx1 = currx + (2.0 / 3.0 * (qx - currx));
                cy1 = curry + (2.0 / 3.0 * (qy - curry));
                currx = getFloat(str,&idx);
                curry = getFloat(str,&idx);
                cx2 = currx + (2.0 / 3.0 * (qx - currx));
                cy2 = curry + (2.0 / 3.0 * (qy - curry));
                lastcurvepoint = NSMakePoint(qx,qy);
                [path curveToPoint:NSMakePoint(currx, curry) controlPoint1:NSMakePoint(cx1, cy1) controlPoint2:NSMakePoint(cx2, cy2)];
                implicitCommand = 'T';
                break;
            case 't':
                if (! stringContainsChar(@"QqTt",lastCommand))
                    lastcurvepoint = NSZeroPoint;
                dx = currx - lastcurvepoint.x;
                dy = curry - lastcurvepoint.y;
                qx = currx + dx;
                qy = curry + dy;
                cx1 = currx + (2.0 / 3.0 * (qx - currx));
                cy1 = curry + (2.0 / 3.0 * (qy - curry));
                currx += getFloat(str,&idx);
                curry += getFloat(str,&idx);
                cx2 = currx + (2.0 / 3.0 * (qx - currx));
                cy2 = curry + (2.0 / 3.0 * (qy - curry));
                lastcurvepoint = NSMakePoint(qx,qy);
                [path curveToPoint:NSMakePoint(currx, curry) controlPoint1:NSMakePoint(cx1, cy1) controlPoint2:NSMakePoint(cx2, cy2)];
                implicitCommand = 't';
                break;
            case 'A':
                rx = getFloat(str,&idx);
                ry = getFloat(str,&idx);
                xrot = getFloat(str,&idx);
                largearcflag = getFloat(str,&idx);
                sweepflag = getFloat(str,&idx);
                currx = getFloat(str,&idx);
                curry = getFloat(str,&idx);
                [path lineToPoint:NSMakePoint(currx, curry)];
                implicitCommand = 'A';
                break;
            case 'a':
                rx = getFloat(str,&idx);
                ry = getFloat(str,&idx);
                xrot = getFloat(str,&idx);
                largearcflag = getFloat(str,&idx);
                sweepflag = getFloat(str,&idx);
                currx += getFloat(str,&idx);
                curry += getFloat(str,&idx);
                [path lineToPoint:NSMakePoint(currx, curry)];
                implicitCommand = 'a';
                break;

            case 'z':
            case 'Z':
                [path closePath];
                break;
            default:
                break;
        }
        idx = skipdelims(str,idx);
    }
    return path;
}

@implementation SVG_path

-(void)processOtherAttributes:(NSDictionary*)context
{
    if (self.resolvedAttributes[@"d"])
    {
        NSBezierPath *p = BezierPathFromSVGPath(self.resolvedAttributes[@"d"]);
        self.processedAttributes[@"_path"] = p;
    }
}

-(NSBezierPath*)path
{
    return self.processedAttributes[@"_path"];
}

@end
