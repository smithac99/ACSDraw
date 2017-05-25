//
//  GraphicView+GraphicViewAdditions.m
//  ACSDraw
//
//  Created by Alan on 17/01/2014.
//
//

#import "GraphicView+GraphicViewAdditions.h"
#import "ACSDLayer.h"
#import "ACSDGraphic.h"
#import "ACSDPage.h"

@implementation GraphicView (GraphicViewAdditions)

static NSPoint relativePositionInRect(CGPoint p,NSRect r)
{
    p.x -= r.origin.x;
    p.y = r.origin.y + r.size.height - p.y;
    p.x /= r.size.width;
    p.y /= r.size.height;
    return p;
}

-(NSString*)maskStringForPage:(ACSDPage*)p
{
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"name beginswith[c] 'm'"];
    NSArray *layers = [[p layers] filteredArrayUsingPredicate:pred];
    if ([layers count] == 0)
        return @"";
    ACSDLayer *layer = layers[0];
    if ([[layer graphics]count] == 0)
        return @"";
    ACSDGraphic *g = [layer graphics][0];
    NSPoint pt = relativePositionInRect([g centrePoint], [self bounds]);
    NSString *mstr = @"mask";
    if (pt.x > 0.5)
        mstr = @"maskr";
    mstr = [NSString stringWithFormat:@"\t\t<img id=\"mask\" filename=\"%@\" pos=\"%g,0.5\"/>\n",mstr,pt.x];
    
    pred = [NSPredicate predicateWithFormat:@"name =[c] 'p1'"];
    layers = [[p layers] filteredArrayUsingPredicate:pred];
    if ([layers count] == 0)
        return mstr;
    layer = layers[0];
    if ([[layer graphics]count] == 0)
        return mstr;
    ACSDGraphic *main = [layer graphics][0];
    pt = relativePositionInRect([main centrePoint], [g bounds]);
    NSString *mainstr = [NSString stringWithFormat:@"\t\t<img id=\"main\" filename=\"page%d\" pos=\"%g,%g\" scale=\"%g\" />\n",(int)[p pageNo],pt.x,pt.y,[main xScale]];
    mstr = [mstr stringByAppendingString:mainstr];
    
    pred = [NSPredicate predicateWithFormat:@"name =[c] 'tx'"];
    layers = [[p layers] filteredArrayUsingPredicate:pred];
    if ([layers count] == 0)
        return mstr;
    ACSDLayer *txlayer = layers[0];
    if ([[txlayer graphics]count] == 0)
        return mstr;
    
    pred = [NSPredicate predicateWithFormat:@"name beginswith[c] 'mainrect'"];
    NSArray *graphics = [[txlayer graphics] filteredArrayUsingPredicate:pred];
    if ([graphics count] == 0)
        return mstr;

    ACSDGraphic *txbox = graphics[0];
    pt = relativePositionInRect([txbox centrePoint], [self bounds]);
    NSString *txstr = [NSString stringWithFormat:@"\t\t<img id=\"textrect\" filename=\"mainrect\" pos=\"%g,%g\"/>\n",pt.x,pt.y];
    mstr = [mstr stringByAppendingString:txstr];
    mstr = [mstr stringByAppendingString:@"\t</images>\n"];

    pred = [NSPredicate predicateWithFormat:@"name =[c] 'p2'"];
    layers = [[p layers] filteredArrayUsingPredicate:pred];
    if ([layers count] == 0)
        return mstr;
    layer = layers[0];
    if ([[layer graphics]count] == 0)
        return mstr;
    main = [layer graphics][0];
    pt = relativePositionInRect([main centrePoint], [g bounds]);
    mainstr = [NSString stringWithFormat:@"\t\t<kb id=\"maingroup\" scale=\"%g\" pos=\"%g,%g\" duration=\"4\" />\n",[main xScale],pt.x,pt.y];
    mstr = [mstr stringByAppendingString:mainstr];

    mstr = [mstr stringByAppendingString:@"\t<lines>\n"];
    NSMutableArray *boxes = [[txlayer graphics]mutableCopy];
    [boxes removeObject:txbox];
    [boxes sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        if ([obj1 bounds].origin.y > [obj2 bounds].origin.y)
            return NSOrderedAscending;
        else if ([obj1 bounds].origin.y < [obj2 bounds].origin.y)
            return NSOrderedDescending;
        return NSOrderedSame;
    }];
    for (ACSDGraphic *box in boxes)
    {
        NSRect frame = [box bounds];
        pt = NSMakePoint(frame.origin.x, frame.origin.y + frame.size.height);
        pt = relativePositionInRect(pt, [txbox bounds]);
        mstr = [mstr stringByAppendingString:[NSString stringWithFormat:@"\t\t<line pos=\"%g,%g\"></line>\n",pt.x,pt.y]];
    }
    mstr = [mstr stringByAppendingString:@"\t</lines>\n"];

    return mstr;

}

-(NSString*)allPagesXML
{
    NSMutableString *str = [NSMutableString stringWithCapacity:200];
    for (ACSDPage *p in pages)
    {
        [str appendString:@"<section>\n\t<images>\n"];
        [str appendString:[self maskStringForPage:p]];
        [str appendString:@"\t</images>\n"];
        [str appendString:@"</section>\n"];
    }
    return str;
}

- (IBAction)cmd1:(id)menuItem
{
	NSSavePanel *sp;
	NSString *fName = [[[self document] displayName]stringByDeletingPathExtension];
	sp = [NSSavePanel savePanel];
	[sp setAllowedFileTypes:nil];
	[sp setTitle:@"Export XMLs"];
	[sp setNameFieldStringValue:fName];
	[sp beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result)
	 {
		 if (result == NSFileHandlingPanelOKButton)
		 {
			 NSURL *url = [(NSSavePanel*)sp URL];
			 NSFileManager *fileManager = [NSFileManager defaultManager];
			 NSError *err;
			 if ([fileManager fileExistsAtPath:[url path]])
				 [fileManager removeItemAtURL:url error:nil];
			 if (![fileManager createDirectoryAtPath:[url path] withIntermediateDirectories:NO attributes:nil error:&err])
			 {
				 NSLog(@"Error creating directory: %@, %@",[url path],[err localizedDescription]);
				 return;
			 }
			 for (ACSDPage *page in [self pages])
			 {
                 NSString *pageName = [NSString stringWithFormat:@"page%d.xml",(int)[page pageNo]];
                 NSMutableString *str = [NSMutableString stringWithCapacity:200];
                 [str appendString:@"<section>\n\t<images>\n"];
                 [str appendString:[self maskStringForPage:page]];
                 [str appendString:@"</section>\n"];
                 NSError *err;
                 if (![str writeToURL:[url URLByAppendingPathComponent:pageName] atomically:NO encoding:NSUnicodeStringEncoding error:&err])
                     NSBeep();
			 }
		 }
	 }
	 ];
}

@end
