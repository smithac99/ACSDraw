//
//  ACSDLabel.mm
//  ACSDraw
//
//  Created by alan on 02/01/06.
//  Copyright 2006 Alan C Smith. All rights reserved.
//

#import "ACSDLabel.h"
#import "ACSDGraphic.h"
#import "ACSDSubPath.h"
#import "gSubPath.h"
#import "SVGWriter.h"


@implementation ACSDLabel

- (id)init
   {
    if (self = [super init])
       {
        contents = [[NSTextStorage allocWithZone:[self zone]] init];
		verticalPosition = 0.0;
		horizontalPosition = 0.0;
		flipped = NO;
		graphic = nil;
       }
    return self;
   }

- (id)initWithGraphic:(ACSDGraphic*)g
   {
    if (self = [self init])
       {
        graphic = g;
       }
    return self;
   }

- (id)initWithGraphic:(ACSDGraphic*)g contents:(NSTextStorage*)c verticalPosition:(float)vP horizontalPosition:(float)hP flipped:(bool)flip 
   {
    if (self = [super init])
       {
        graphic = g;
		contents = [c retain];
		verticalPosition = vP;
		horizontalPosition = hP;
		flipped = flip;
       }
    return self;
   }

-(void)dealloc
   {
	if (contents)
		[contents release];
	[super dealloc];
   }

- (id)copyWithZone:(NSZone *)zone
   {
	NSTextStorage *tCopy = [[NSTextStorage alloc]initWithAttributedString:[self contents]];
    ACSDLabel *newObj = [[[self class] allocWithZone:zone]initWithGraphic:graphic contents:[tCopy autorelease] verticalPosition:verticalPosition
									   horizontalPosition:horizontalPosition flipped:flipped];
    return newObj;
   }

- (void) encodeWithCoder:(NSCoder*)coder
   {
	[coder encodeConditionalObject:graphic forKey:@"ACSDLabel_graphic"];
	[coder encodeObject:[self contents] forKey:@"ACSDLabel_contents"];
	[coder encodeFloat:verticalPosition forKey:@"ACSDText_verticalPosition"];
	[coder encodeFloat:horizontalPosition forKey:@"ACSDText_horizontalPosition"];
	[coder encodeBool:flipped forKey:@"ACSDText_flipped"];
   }

- (id) initWithCoder:(NSCoder*)coder
   {
	self = [self init];
	[self setGraphic:[coder decodeObjectForKey:@"ACSDLabel_graphic"]];
	[self setContents:[[[NSTextStorage allocWithZone:[self zone]] initWithAttributedString:[coder decodeObjectForKey:@"ACSDLabel_contents"]]autorelease]];
	verticalPosition = [coder decodeFloatForKey:@"ACSDText_verticalPosition"];
	horizontalPosition = [coder decodeFloatForKey:@"ACSDText_horizontalPosition"];
	flipped = [coder decodeBoolForKey:@"ACSDText_flipped"];
	return self;
   }

- (NSTextStorage*)contents
   {
	return contents;
   }

- (void)setContents:(NSTextStorage*)cont
   {
    if (contents == cont)
		return;
    if (contents)
		[contents release];
	contents = [cont retain];
   }

- (void)setLabel:(NSTextStorage*)cont
   {
	[contents setAttributedString:cont];
   }

- (void)setGraphic:(ACSDGraphic*)g
   {
    graphic = g;
   }

- (float)verticalPosition
   {
    return verticalPosition;
   }

- (float)horizontalPosition
   {
    return horizontalPosition;
   }


- (void)setVerticalPosition:(float)vp
   {
    verticalPosition = vp;
   }

- (void)setHorizontalPosition:(float)hp
   {
    horizontalPosition = hp;
   }

- (void)setFlipped:(BOOL)f
   {
    flipped = f;
   }

- (BOOL)flipped
   {
    return flipped;
   }

- (NSLayoutManager*)layoutmanagerForWidth:(float)width
   {
	NSSize sz;
	sz.width = width;
	sz.height = 1.0e6;
	NSArray *layoutManagers = [[self contents]layoutManagers];
	NSLayoutManager *lm;
	if ([layoutManagers count] == 0)
	   {
		lm = [[[NSLayoutManager alloc] init]autorelease];
		[lm addTextContainer:[[[NSTextContainer alloc]initWithContainerSize:sz]autorelease]];
		[[self contents] addLayoutManager:lm];
	   }
	else
	   {
		lm = [layoutManagers objectAtIndex:0];
		[[[lm textContainers] objectAtIndex:0] setContainerSize:sz];
	   }
	return lm;
   }

- (NSSize)sizeOfLaidOutText
   {
	NSLayoutManager *lm = [[[self contents]layoutManagers]objectAtIndex:0];
	NSTextContainer *tc = [[lm textContainers] objectAtIndex:0];
	[lm glyphRangeForTextContainer:tc];
	NSRect r = [lm usedRectForTextContainer:tc];
	return r.size;
   }


-(float)paddingRequiredForPath:(NSBezierPath*)bzP
   {
	if ([contents length] == 0)
		return 0.0;
	NSMutableArray *gSubPaths = [gSubPath gSubPathsFromACSDSubPaths:[ACSDSubPath subPathsFromBezierPath:bzP]];
	float len = 0.0;
    NSEnumerator *objEnum = [gSubPaths objectEnumerator];
    gSubPath *gel;
    while ((gel = [objEnum nextObject]) != nil)
	   {
		[gel setLengthFrom:len];
		len += [gel length];
	   }
	[self layoutmanagerForWidth:len];
	NSSize textSize = [self sizeOfLaidOutText];
	return textSize.height + fabs(verticalPosition);
   }

- (void)drawForPath:(NSBezierPath*)bzP
{
	if ([contents length] == 0)
		return;
	if (flipped)
		bzP = [bzP bezierPathByReversingPath];
	NSMutableArray *gSubPaths = [gSubPath gSubPathsFromACSDSubPaths:[ACSDSubPath subPathsFromBezierPath:bzP]];
	float len = 0.0;
	NSEnumerator *objEnum = [gSubPaths objectEnumerator];
	gSubPath *gel;
	while ((gel = [objEnum nextObject]) != nil)
	{
		[gel setLengthFrom:len];
		len += [gel length];
	}
	NSLayoutManager *lm = [self layoutmanagerForWidth:len];
	NSSize textSize = [self sizeOfLaidOutText];
	float leftMargin = ((len - textSize.width) / 2) * (horizontalPosition + 1);
	if (textSize.width == 0.0 || textSize.height == 0.0)
		return;
	NSTextContainer *tc = [[lm textContainers] objectAtIndex:0];
	NSRange glyphRange = [lm glyphRangeForTextContainer:tc];
	if (glyphRange.length == 0)
		return;
	float yOf = 0.0;
	for (NSUInteger glyphIndex = glyphRange.location; glyphIndex < NSMaxRange(glyphRange); glyphIndex++)
	{
		NSRect lineFragmentRect = [lm lineFragmentRectForGlyphAtIndex:glyphIndex effectiveRange:NULL];
		if (glyphIndex == glyphRange.location)
			yOf = (lineFragmentRect.origin.y + lineFragmentRect.size.height);
		NSRect glyphBounds = [lm boundingRectForGlyphRange:NSMakeRange(glyphIndex,1) inTextContainer:tc];
		float width2 = glyphBounds.size.width / 2;
		float transformLocationX = leftMargin + glyphBounds.origin.x + lineFragmentRect.origin.x + width2;
		NSPoint layoutLocation = [lm locationForGlyphAtIndex:glyphIndex];
		
		// Here layoutLocation is the location (in container coordinates) where the glyph was laid out.
		layoutLocation.x += lineFragmentRect.origin.x;
		layoutLocation.x += leftMargin;
		layoutLocation.y += lineFragmentRect.origin.y;
		
		NSAffineTransform *transform = [gSubPath transformForLength:transformLocationX fromGSubPaths:gSubPaths];
		
		BOOL isflipped = [[NSView focusView]isFlipped];
		[[NSGraphicsContext currentContext] saveGraphicsState];
		if ([[NSView focusView] respondsToSelector:@selector(setFlipped:)])
			[(id)[NSView focusView]setFlipped:YES];
		
		[transform concat];
		
		/*NSAffineTransform *tr = [NSAffineTransform transform];
		[tr scaleXBy:1.0 yBy:-1.0];
		[tr concat];*/

		[[NSGraphicsContext currentContext] saveGraphicsState];
		NSAffineTransform *tr = [NSAffineTransform transform];
		if ([[NSGraphicsContext currentContext] isFlipped])
		{
			[tr scaleXBy:1.0 yBy:-1.0];
			[tr translateXBy:0 yBy:-yOf];
		}
		else
			[tr translateXBy:0 yBy:yOf-(layoutLocation.y * 2)+verticalPosition];
		[tr concat];

		[lm drawGlyphsForGlyphRange:NSMakeRange(glyphIndex, 1) atPoint:NSMakePoint(-(transformLocationX - leftMargin),0)];
		
		[[NSGraphicsContext currentContext] restoreGraphicsState];
		
		if ([[NSView focusView] respondsToSelector:@selector(setFlipped:)])
			[(id)[NSView focusView]setFlipped:isflipped];
		[[NSGraphicsContext currentContext] restoreGraphicsState];
	}
}

-(void)writeSVGData:(SVGWriter*)svgWriter
   {
	if ([contents length] == 0)
		return;
	NSSize docSize = [[svgWriter document] documentSize];
	NSAffineTransform *t = [NSAffineTransform transform];
	[t translateXBy:0 yBy:docSize.height];
	[t scaleXBy:1 yBy:-1];
	NSBezierPath *bzp = [[[graphic transformedBezierPath]copy]autorelease];
	[bzp transformUsingAffineTransform:t];
	NSMutableArray *gSubPaths = [gSubPath gSubPathsFromACSDSubPaths:[ACSDSubPath subPathsFromBezierPath:[graphic transformedBezierPath]]];
	float len = 0.0;
    NSEnumerator *objEnum = [gSubPaths objectEnumerator];
    gSubPath *gel;
    while ((gel = [objEnum nextObject]) != nil)
	   {
		[gel setLengthFrom:len];
		len += [gel length];
	   }
	NSLayoutManager *lm = [self layoutmanagerForWidth:len];
	NSSize textSize = [self sizeOfLaidOutText];
	if (textSize.width == 0.0 || textSize.height == 0.0)
		return;
	float leftMargin = ((len - textSize.width) / 2) * (horizontalPosition + 1);
	NSTextContainer *tc = [[lm textContainers] objectAtIndex:0];
	NSRange glyphRange = [lm glyphRangeForTextContainer:tc];
	if (glyphRange.length == 0)
		return;
	[[svgWriter defs]appendFormat:@"<path id=\"_p_%@\" d=\"%@\" />",[graphic name],string_from_path(bzp)];
	[[svgWriter contents]appendString:@"<text transform=\""];
	[[svgWriter contents]appendFormat:@" translate(0,%g) scale(1,-1)\">\n",docSize.height];
	float yOf = 0.0;
	NSUInteger glyphCount = [lm numberOfGlyphs];
	for (unsigned glyphIndex = 0;glyphIndex < glyphCount;)
	   {
		[[svgWriter contents]appendFormat:@"<textPath xlink:href=\"#_p_%@\" startOffset=\"%g\">\n",[graphic name],leftMargin];
		NSRect glyphRect = [lm lineFragmentRectForGlyphAtIndex:glyphIndex effectiveRange:&glyphRange];
		float oldOf = 0.0;
		if (glyphIndex == 0)
		   {
			NSPoint layoutLocation = [lm locationForGlyphAtIndex:glyphIndex];
			yOf = (glyphRect.size.height - layoutLocation.y);
		   }
		NSAttributedString *lineString = [contents attributedSubstringFromRange:glyphRange];
		for (unsigned int i = 0;i < glyphRange.length;)
		   {
			NSRange attributeRange;
			NSDictionary *attributeDict	= [lineString attributesAtIndex:i effectiveRange:&attributeRange];
			if (attributeRange.location < i)
			   {
				attributeRange.length -= (i - attributeRange.location);
				attributeRange.location = i;
			   }
			NSRange tabRange = [[lineString string]rangeOfString:@"\t" options:NSLiteralSearch range:attributeRange];
			if (tabRange.location != NSNotFound)
			   {
				if (tabRange.location >= [lineString length])
					NSLog(@"shouldn't happen");
				
				attributeRange.length = tabRange.location + 1 - attributeRange.location;
			   }
			[lm locationForGlyphAtIndex:glyphRange.location + i];
			NSFont *font = [attributeDict objectForKey:NSFontAttributeName];
			NSColor *col = [attributeDict objectForKey:NSForegroundColorAttributeName];
			int underlined = [[attributeDict objectForKey:NSUnderlineStyleAttributeName]intValue];
			NSFontTraitMask fontMask = [[NSFontManager sharedFontManager]traitsOfFont:font];
			[[svgWriter contents] appendString:@"<tspan "];
			float offset = glyphRect.origin.y - yOf;
			if (offset != oldOf)
			   {
				[[svgWriter contents] appendFormat:@"dy=\"%g\" ",offset-oldOf-verticalPosition];
				oldOf = offset;
			   }
			[[svgWriter contents] appendFormat:@"font-family=\"%@\" font-size=\"%f\"",
				[font familyName],[font pointSize]];
			if (fontMask & NSBoldFontMask)
				[[svgWriter contents] appendString:@" font-weight=\"bold\""];
			if (fontMask & NSItalicFontMask)
				[[svgWriter contents] appendString:@" font-style=\"italic\""];
			if (underlined)
				[[svgWriter contents] appendString:@" text-decoration=\"underline\""];
			NSString *printString = substitute_characters([[lineString attributedSubstringFromRange:attributeRange]string]);
			[[svgWriter contents] appendFormat:@" fill=\"%@\" >%@</tspan>\n",string_from_nscolor(col),printString];
			i += attributeRange.length;
		   }
		glyphIndex += glyphRange.length;
		[[svgWriter contents]appendString:@"</textPath>\n"];
	   }
	[[svgWriter contents]appendString:@"</text>\n"];
   }

@end
