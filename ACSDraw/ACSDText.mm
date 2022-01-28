//
//  ACSDText.mm
//  ACSDraw
//
//  Created by Alan Smith on Thu Jan 31 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "ACSDText.h"
#import "ACSDTextStorage.h"
#import "ACSDPath.h"
#import "ACSDPage.h"
#import "GraphicView.h"
#import "ShadowType.h"
#import "SVGWriter.h"
#import "ShadowType.h"
#import "AffineTransformAdditions.h"
#import "TextStyleHolder.h"
#import "ACSDStyle.h"
#import "ACSDLink.h"
#import "AppDelegate.h"
#import "ACSDPrefsController.h"
#import "StyleWindowController.h"
#import "ACSDTextContainer.h"
#import "GraphicView.h"
#import "TextSubstitution.h"
#import "CanvasWriter.h"
#import "ACSDLineEnding.h"
#import "geometry.h"
#import "XMLNode.h"

NSString *ACSDAnchorAttributeName = @"ACSDAnchor";
NSString *ACSDrawTextPBoardType = @"ACSDrawTextPBoardType";

NSAttributedString* stripWhiteSpaceFromAttributedString(NSAttributedString* mas);
NSString *substitute_characters(NSString* string);

NSString *substitute_characters(NSString* string)
   {
	NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:@"&<>"];
	NSMutableString *resultString = [NSMutableString stringWithCapacity:[string length]];
	[resultString appendString:string];
	NSRange searchRange;
	searchRange.location = 0;
	searchRange.length = [resultString length];
	NSRange findPosition = [resultString rangeOfCharacterFromSet:charSet options:NSLiteralSearch range:searchRange];
	while (searchRange.location < [resultString length] && findPosition.location != NSNotFound)
	   {
		NSString *foundString = [resultString substringWithRange:findPosition];
		if ([foundString isEqualToString:@"&"])
		   {
			[resultString replaceCharactersInRange:findPosition withString:@"&amp;"];
			searchRange.location = findPosition.location + 5;
		   }
		else if ([foundString isEqualToString:@"<"])
		   {
			[resultString replaceCharactersInRange:findPosition withString:@"&lt;"];
			searchRange.location = findPosition.location + 4;
		   }
		else if ([foundString isEqualToString:@">"])
		   {
			[resultString replaceCharactersInRange:findPosition withString:@"&gt;"];
			searchRange.location = findPosition.location + 4;
		   }
		searchRange.length = [resultString length] - searchRange.location;
		findPosition = [resultString rangeOfCharacterFromSet:charSet options:NSLiteralSearch range:searchRange];
	   }
	while ([resultString length] > 0 && ([resultString characterAtIndex:[resultString length] - 1] == '\n'))
		[resultString deleteCharactersInRange:NSMakeRange([resultString length] - 1,1)];
	return resultString;
   }

@implementation ACSDText

+ (NSString*)graphicTypeName
   {
	return @"Text";
   }

+ (ACSDText*)dupAndFlowText:(ACSDText*)graphic
   {
	ACSDText *gCopy = [[graphic copy]autorelease];
	[gCopy linkToText:graphic];
	return gCopy;
   }

+(id)textWithXMLNode:(XMLNode*)xmlnode settingsStack:(NSMutableArray*)settingsStack
{
    NSDictionary *settings = [settingsStack lastObject];
    NSRect parentRect = [settings[@"parentrect"]rectValue];
    
    float x = [xmlnode attributeFloatValue:@"x"];
    float y = [xmlnode attributeFloatValue:@"y"];
    float width = [xmlnode attributeFloatValue:@"width"];
    float height = [xmlnode attributeFloatValue:@"height"];
    
    //parentRect = InvertedRect(parentRect, docHeight);
    width = width * parentRect.size.width;
    height = height * parentRect.size.height;
    NSPoint pos = LocationForRect(x, 1 - y, parentRect);
    ACSDText *t = [[ACSDText alloc]initWithName:@"" fill:nil stroke:nil rect:NSMakeRect(pos.x, pos.y - height, width, height) layer:nil];
    NSString *fontFamily = @"Helvetica";
    float fontSize = 12;
    NSColor *textFill = [NSColor blackColor];
    NSFont *f = [NSFont fontWithName:fontFamily size:fontSize];
    NSMutableAttributedString *mas = [[[NSMutableAttributedString alloc]initWithString:@"" attributes:@{NSFontAttributeName:f,
                                                                                                        NSForegroundColorAttributeName:textFill
                                                                                                        }]autorelease];
    for (XMLNode *xspan in [xmlnode childrenOfType:@"tspan"])
    {
        NSMutableDictionary *options = [NSMutableDictionary dictionary];
        NSString *c = [xspan contents];
        NSColor *fill = [fillFromNodeAttributes(xspan.attributes) colour];
        NSString *fo = [xspan attributeStringValue:@"font-family"];
        if (fo == nil)
            fo = fontFamily;
        float fs;
        NSString *fss = [xspan attributeStringValue:@"font-size"];
        if (fss)
            fs = [fss floatValue];
        else
            fs = fontSize;
        fontFamily = fo;
        fontSize = fs;
        options[NSFontAttributeName] = [NSFont fontWithName:fontFamily size:fontSize];
        if (fill)
        {
            textFill = fill;
            options[NSForegroundColorAttributeName] = fill;
        }
        [mas appendAttributedString:[[[NSAttributedString alloc]initWithString:c attributes:options]autorelease]];
    }
        NSTextStorage *contents = [[NSTextStorage allocWithZone:[self zone]] initWithAttributedString:mas];
        //        contents = [[ACSDTextStorage allocWithZone:[self zone]] initWithAttributedString:astr];
        [contents addLayoutManager:[t layoutManager]];

    [t setContents:contents];
    return t;
}

- (id)initWithName:(NSString*)n fill:(ACSDFill*)f stroke:(ACSDStroke*)str rect:(NSRect)r layer:(ACSDLayer*)l
   {
    if ((self = [super initWithName:n fill:f stroke:str rect:r layer:l]))
       {
        previousText = nextText = nil;
		overflow = NO;
		contents = [[NSTextStorage allocWithZone:[self zone]] init];
		cornerRadius = 0.0;
//		contents = [[ACSDTextStorage allocWithZone:[self zone]] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contentsChanged:) 
			name:NSTextStorageDidProcessEditingNotification object:contents];
		leftMargin = rightMargin = topMargin = bottomMargin = 0.0;
		verticalAlignment = VERTICAL_ALIGNMENT_TOP;
		[contents addLayoutManager:[self layoutManager]];
		mayContainSubstitutions = NO;
       }
    return self;
   }

- (id)initWithName:(NSString*)n fill:(ACSDFill*)f stroke:(ACSDStroke*)str rect:(NSRect)r layer:(ACSDLayer*)l
			xScale:(float)xs yScale:(float)ys rotation:(float)rot shadowType:(ShadowType*)st label:(ACSDLabel*)lab alpha:(float)a contents:(NSTextStorage*)cont
		topMargin:(float)tm leftMargin:(float)lm bottomMargin:(float)bm rightMargin:(float)rm verticalAlignment:(VerticalAlignment)vA
   {
    if ((self = [self initWithName:n fill:f stroke:str rect:r layer:l
						   xScale:xs yScale:ys rotation:rot shadowType:st label:lab alpha:a]))
       {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contentsChanged:) 
													 name:NSTextStorageDidProcessEditingNotification object:contents];
        previousText = nextText = nil;
		overflow = NO;
		contents = [cont retain];
		leftMargin = lm;
		rightMargin = rm;
		topMargin = tm;
		bottomMargin = bm;
		verticalAlignment = vA;
		[contents addLayoutManager:[self layoutManager]];
		mayContainSubstitutions = NO;
	   }
	return self;
   }

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[contents release];
	[objectsInTheWay release];
	[objectsInFront release];
	[pathInTheWay release];
	if (layoutManager && !previousText)
		[layoutManager release];
    [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone
{
    NSTextStorage *c = [[[NSTextStorage alloc] initWithAttributedString:contents]autorelease];
	id obj = [[ACSDText alloc]initWithName:self.name fill:fill stroke:stroke rect:bounds layer:layer
									xScale:xScale yScale:yScale rotation:rotation shadowType:shadowType label:textLabel alpha:alpha contents:c
								 topMargin:topMargin leftMargin:leftMargin bottomMargin:bottomMargin rightMargin:rightMargin verticalAlignment:verticalAlignment];
	[(ACSDText*)obj setCornerRadius:cornerRadius];
    [obj setAttributes:[[self.attributes mutableCopy]autorelease]];
	return obj;
}

- (void) encodeWithCoder:(NSCoder*)coder
   {
	[super encodeWithCoder:coder];
	[coder encodeObject:[self contents] forKey:@"ACSDText_contents"];
	[coder encodeFloat:topMargin forKey:@"ACSDText_topMargin"];
	[coder encodeFloat:leftMargin forKey:@"ACSDText_leftMargin"];
	[coder encodeFloat:bottomMargin forKey:@"ACSDText_bottomMargin"];
	[coder encodeFloat:rightMargin forKey:@"ACSDText_rightMargin"];
	[coder encodeInt:verticalAlignment forKey:@"ACSDText_verticalAlignment"];
	[coder encodeInt:flowMethod forKey:@"ACSDText_flowMethod"];
	[coder encodeConditionalObject:previousText forKey:@"ACSDText_previousText"];
	[coder encodeConditionalObject:nextText forKey:@"ACSDText_nextText"];
	[coder encodeInt:maxAnchorID forKey:@"ACSDText_maxAnchorID"];
	[coder encodeFloat:cornerRadius forKey:@"ACSDText_cornerRadius"];
	[coder encodeFloat:flowPad forKey:@"ACSDText_flowPad"];
   }

+(void)sortOutLinkedTextGraphics:(ACSDText*)startText
   {
	ACSDText *currText = [startText nextText];
	while (currText)
	   {
		[[startText layoutManager]addTextContainer:[currText textContainer]];
		currText = [currText nextText];
	   }
   }

- (id) initWithCoder:(NSCoder*)coder
   {
	self = [super initWithCoder:coder];
	previousText = [coder decodeObjectForKey:@"ACSDText_previousText"];
//	if (previousText)
//		textContainer = [[ACSDTextContainer allocWithZone:NULL] initWithContainerSize:bounds.size graphic:self];
	NSAttributedString *astr = [coder decodeObjectForKey:@"ACSDText_contents"];
	if (astr)
	   {
		contents = [[NSTextStorage allocWithZone:[self zone]] initWithAttributedString:astr];
//		contents = [[ACSDTextStorage allocWithZone:[self zone]] initWithAttributedString:astr];
		[contents addLayoutManager:[self layoutManager]];
	   }
	else
		contents = nil;
	nextText = [coder decodeObjectForKey:@"ACSDText_nextText"];
	cornerRadius = [coder decodeFloatForKey:@"ACSDText_cornerRadius"];
	overflow = NO;
	topMargin = [coder decodeFloatForKey:@"ACSDText_topMargin"];
	leftMargin = [coder decodeFloatForKey:@"ACSDText_leftMargin"];
	bottomMargin = [coder decodeFloatForKey:@"ACSDText_bottomMargin"];
	rightMargin = [coder decodeFloatForKey:@"ACSDText_rightMargin"];
	verticalAlignment = (VerticalAlignment)[coder decodeIntForKey:@"ACSDText_verticalAlignment"];
	flowMethod = [coder decodeIntForKey:@"ACSDText_flowMethod"];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contentsChanged:) 
		name:NSTextStorageDidProcessEditingNotification object:contents];
	handlePoints = new NSPoint[8];
	noHandlePoints = 8;
	maxAnchorID = [coder decodeIntForKey:@"ACSDText_maxAnchorID"];
//	if (previousText == nil && nextText != nil)
//		[ACSDText sortOutLinkedTextGraphics:self];
	flowPad = [coder decodeFloatForKey:@"ACSDText_flowPad"];
	return self;
   }

-(void)allocateTextSystemStuff
   {
    layoutManager = [[NSLayoutManager allocWithZone:NULL] init];
//    textContainer = [[ACSDTextContainer allocWithZone:NULL] initWithContainerSize:bounds.size graphic:self];
    [layoutManager addTextContainer:[self textContainer]];
    [contents addLayoutManager:[layoutManager autorelease]];
	[layoutManager setDelegate:self];
	overflow = NO;
   }

-(NSRange)characterRange
   {
	NSRange glyphRange = [[self layoutManager] glyphRangeForTextContainer:[self textContainer]];
	return [[self layoutManager] characterRangeForGlyphRange:glyphRange actualGlyphRange:nil];
   }

-(BOOL)canBeMask
   {
	return YES;
   }

-(BOOL)isEditable
   {
    return YES;
   }

- (NSTextStorage*)contents
   {
	return contents;
   }

- (void)setContents:(id)cont
   {
    if (cont == contents)
		return;
	if (contents)
		[contents release];
	contents = cont;
	if (contents)
	   {
		[contents retain];
		[self allocateTextSystemStuff];
	   }
   }

-(float)paddingRequired
   {
    float padding = [super paddingRequired];
	if (padding < ACSD_HANDLE_WIDTH + 1.0)
		return ACSD_HANDLE_WIDTH + 1.0;
	return padding;
   }
    
- (void)startBoundsManipulation
{
    [super startBoundsManipulation];
    originalCornerRadius = cornerRadius;
	originalCornerRatio = 0.0;
	if (cornerRadius != 0.0)
	{
		float smallSide = fmin(bounds.size.width,bounds.size.height);
		if (smallSide != 0.0)
			originalCornerRatio = cornerRadius/smallSide;
	}
}

-(void)setGraphicCornerRadius:(float)rad from:(float)oldRad notify:(BOOL)notify
{
	if (rad == oldRad)
		return;
	if (!manipulatingBounds)
		[[[self undoManager] prepareWithInvocationTarget:self] setGraphicCornerRadius:oldRad from:rad notify:YES];
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
	[self setCornerRadius:rad];
	[self invalidateGraphicSizeChanged:YES shapeChanged:NO redraw:YES notify:notify];
}

- (void)stopBoundsManipulation
{
    if (manipulatingBounds)
	{
        if (!NSEqualRects(originalBounds,bounds))
		{
            manipulatingBounds = NO;
			cornerRadius = originalCornerRadius;
            [self setGraphicBoundsTo:bounds from:originalBounds];
			//            [self setGraphicCornerRadius:cornerRadius from:originalCornerRadius notify:YES];
		}
		else
			manipulatingBounds = NO;
	}
}

-(BOOL)setGraphicCornerRadius:(float)r notify:(BOOL)notify
{
	if (r == cornerRadius)
		return NO;
	if (!manipulatingBounds)
		[[[self undoManager] prepareWithInvocationTarget:self] setGraphicCornerRadius:cornerRadius notify:YES];
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
	[self setCornerRadius:r];
	[self invalidateGraphicSizeChanged:YES shapeChanged:NO redraw:YES notify:notify];
	return YES;
}

-(float)maxCornerRadius
{
	return fmin(bounds.size.width,bounds.size.height)/2.0;
}

- (void)setGraphicContents:(id)cont
   {
    if (cont != contents)
	   {
        NSAttributedString *contentsCopy = [[NSAttributedString allocWithZone:[self zone]] initWithAttributedString:contents];
        [[[self undoManager] prepareWithInvocationTarget:self] setGraphicContents:[contentsCopy autorelease]];
        // We are willing to accept either a string or an attributed string.
        if ([cont isKindOfClass:[NSAttributedString class]])
            [contents replaceCharactersInRange:NSMakeRange(0, [contents length]) withAttributedString:cont];
        else
            [contents replaceCharactersInRange:NSMakeRange(0, [contents length]) withString:cont];
		[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:YES notify:NO];
       }
   }

- (float)topMargin
   {
	return topMargin;
   }

- (float)leftMargin
   {
	return leftMargin;
   }

- (float)bottomMargin
   {
	return bottomMargin;
   }

- (float)rightMargin
   {
	return rightMargin;
   }

- (float)flowPad
   {
	return flowPad;
   }

- (void)setTopMargin:(float)m
   {
	topMargin = m;
   }

- (void)setLeftMargin:(float)m
   {
	leftMargin = m;
   }

- (void)setBottomMargin:(float)m
   {
	bottomMargin = m;
   }

- (void)setRightMargin:(float)m
   {
	rightMargin = m;
   }

- (void)setFlowPad:(float)m
   {
	flowPad = m;
   }

- (int)flowMethod
   {
	return flowMethod;
   }

- (void)setFlowMethod:(int)al
   {
	flowMethod = al;
   }

-(float)cornerRadius
{
	return cornerRadius;
}

-(void)setCornerRadius:(float)r
{
	cornerRadius = r;
}

- (VerticalAlignment)verticalAlignment
   {
	return verticalAlignment;
   }

- (void)setVerticalAlignment:(VerticalAlignment)al
   {
	verticalAlignment = al;
   }

- (BOOL)setGraphicFlowPad:(float)m notify:(BOOL)notify
{
	if (m == flowPad)
		return NO;
	[[[self undoManager] prepareWithInvocationTarget:self] setGraphicFlowPad:flowPad notify:YES];
	[self setFlowPad:m];
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:YES notify:notify];
	return YES;
}

- (BOOL)setGraphicLeftMargin:(float)m notify:(BOOL)notify
{
	if (m == leftMargin)
		return NO;
	[[[self undoManager] prepareWithInvocationTarget:self] setGraphicLeftMargin:leftMargin notify:YES];
	[self setLeftMargin:m];
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:YES notify:notify];
	return YES;
}

- (BOOL)setGraphicRightMargin:(float)m notify:(BOOL)notify
{
	if (m == rightMargin)
		return NO;
	[[[self undoManager] prepareWithInvocationTarget:self] setGraphicRightMargin:rightMargin notify:YES];
	[self setRightMargin:m];
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:YES notify:notify];
	return YES;
}

- (BOOL)setGraphicTopMargin:(float)m notify:(BOOL)notify
{
	if (m == topMargin)
		return NO;
	[[[self undoManager] prepareWithInvocationTarget:self] setGraphicTopMargin:topMargin notify:YES];
	[self setTopMargin:m];
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:YES notify:notify];
	return YES;
}

- (BOOL)setGraphicBottomMargin:(float)m notify:(BOOL)notify
{
	if (m == bottomMargin)
		return NO;
	[[[self undoManager] prepareWithInvocationTarget:self] setGraphicBottomMargin:bottomMargin notify:YES];
	[self setBottomMargin:m];
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:YES notify:notify];
	return YES;
}

- (void)setGraphicVerticalAlignment:(VerticalAlignment)a notify:(BOOL)notify
   {
	[[[self undoManager] prepareWithInvocationTarget:self] setGraphicVerticalAlignment:verticalAlignment notify:YES];
	[self setVerticalAlignment:a];
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:YES notify:notify];
   }

- (void)setGraphicFlowMethod:(int)a notify:(BOOL)notify
   {
	if (flowMethod == a)
		return;
	[[[self undoManager] prepareWithInvocationTarget:self] setGraphicFlowMethod:flowMethod notify:YES];
	[self setFlowMethod:a];
	[self setObjectsInFrontValid:NO];
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:YES notify:notify];
	[[self layoutManager]textContainerChangedGeometry:[self textContainer]];
   }

-(BOOL)doesTextFlow
   {
	return flowMethod > FLOW_METHOD_NONE;
   }

- (void)contentsChanged:(NSNotification *)notification
   {
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:YES notify:NO];
   }

-(NSBezierPath*)pathFromText
   {
	NSBezierPath *p = [NSBezierPath bezierPath];
	NSTextStorage *cont = [[self layoutManager] textStorage];
	NSRect b = [self bounds];
	b.origin.x += leftMargin;
	b.origin.y += bottomMargin;
	b.size.width -= (leftMargin + rightMargin);
	b.size.height -= (topMargin + bottomMargin);
	float realContainerheight = b.size.height;
	b.size.height = 10000;
	[[self textContainer] setContainerSize:b.size];
	NSUInteger glyphCount = [[self layoutManager] numberOfGlyphs];
	NSBezierPath *tempPath = [NSBezierPath bezierPath];
	NSBezierPath *underlinePath = [NSBezierPath bezierPath];
	for (int i = 0;i < glyphCount;i++)
	   {
		NSGlyph glyph = [[self layoutManager] glyphAtIndex:i];
		NSUInteger charPos = [[self layoutManager] characterIndexForGlyphAtIndex:i];
		NSDictionary *dict = [cont attributesAtIndex:charPos effectiveRange:NULL];
		NSFont *font = [dict objectForKey:NSFontAttributeName];
		NSPoint loc = [[self layoutManager] locationForGlyphAtIndex:i];
		NSRect r = [[self layoutManager] lineFragmentUsedRectForGlyphAtIndex:i effectiveRange:NULL];
		loc.y = realContainerheight - (r.origin.y + loc.y);
		[tempPath removeAllPoints];
		[tempPath moveToPoint:loc];
		[tempPath appendBezierPathWithGlyph:glyph inFont:font];
		[p appendBezierPath:tempPath];
		id obj;
		if ((obj = [dict objectForKey:NSUnderlineStyleAttributeName]) && [obj intValue])
		   {
			NSRect glyphBounds = [[self layoutManager] boundingRectForGlyphRange:NSMakeRange(i,1) inTextContainer:[self textContainer]];
			float ulpos = [font underlinePosition];
			NSRect r;
			r.origin.x = loc.x;
			r.origin.y = loc.y + ulpos;
			r.size.width = glyphBounds.size.width;
			r.size.height = [font underlineThickness];
			[underlinePath appendBezierPath:[NSBezierPath bezierPathWithRect:r]];
		   }
	   }
	if ([underlinePath elementCount] > 1)
		[p appendBezierPath:underlinePath];
	if (glyphCount > 0)
		if (verticalAlignment != VERTICAL_ALIGNMENT_TOP)
		   {
			NSRect r = [[self layoutManager] usedRectForTextContainer:[self textContainer]];
			float diff = realContainerheight - r.size.height;
			if (diff > 0.0)
			   {
				if (verticalAlignment ==  VERTICAL_ALIGNMENT_BOTTOM)
					b.origin.y -= diff;
				else
					b.origin.y -= (diff / 2.0);
			   }
		   }
	[p transformUsingAffineTransform:[NSAffineTransform transformWithTranslateXBy:b.origin.x yBy:b.origin.y]];
	return p;
   }

- (ACSDPath*)convertToPath
   {
	NSBezierPath *p = [self pathFromText];
	if ([self stroke] && [[self stroke]colour])
		[p appendBezierPath:[self bezierPath]];
	ACSDGraphic *obj =  [[[ACSDPath alloc] initWithName:[self name] fill:[self fill] stroke:[self stroke] rect:[self bounds]
		layer:nil bezierPath:p]autorelease];
	[obj setRotation:rotation];
	if (rotation != 0.0)
	   {
		[obj setRotationPoint:rotationPoint];
		[obj computeTransform];
	   }
	return (ACSDPath*)obj;
   }

-(NSBezierPath*)pathTextGetPath
{
	return [[self convertToPath]transformedBezierPath];
}

-(void)writeCanvasData:(CanvasWriter*)canvasWriter
{
	[[canvasWriter contents]appendString:@"ctx.save();\n"];
	[self writeCanvasGraphic:canvasWriter];
	NSRect b = [self bounds];
	[[canvasWriter contents]appendFormat:@"ctx.translate(%g,%g);ctx.scale(1.0,-1.0);ctx.translate(%g,%g);\n",
	 b.origin.x,b.origin.y,-b.origin.x,-(b.origin.y + b.size.height)];
	NSTextStorage *cont = [[self layoutManager] textStorage];
	b.origin.x += leftMargin;
	b.size.width -= (leftMargin + rightMargin);
	b.origin.y += topMargin;
	b.size.height -= (topMargin + bottomMargin);
	[[self textContainer] setContainerSize:b.size];
	NSRange glyphRange = [[self layoutManager] glyphRangeForTextContainer:[self textContainer]];
	if (verticalAlignment != VERTICAL_ALIGNMENT_TOP)
	{
		NSRect r = [[self layoutManager] usedRectForTextContainer:[self textContainer]];
		float diff = b.size.height - r.size.height;
		if (diff > 0.0)
		{
			if (verticalAlignment ==  VERTICAL_ALIGNMENT_BOTTOM)
				b.origin.y += diff;
			else
				b.origin.y += (diff / 2.0);
		}
	}
	NSUInteger glyphCount = glyphRange.location + glyphRange.length;
	for (NSUInteger glyphIndex = glyphRange.location;glyphIndex < glyphCount;)
	{
		NSRect glyphRect = [[self layoutManager] lineFragmentRectForGlyphAtIndex:glyphIndex effectiveRange:&glyphRange];
		NSPoint loc = glyphRect.origin;
		NSAttributedString *lineString = [cont attributedSubstringFromRange:glyphRange];
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
			NSPoint glyphLoc = [[self layoutManager] locationForGlyphAtIndex:glyphRange.location + i];
			NSFont *font = [attributeDict objectForKey:NSFontAttributeName];
			NSColor *col = [attributeDict objectForKey:NSForegroundColorAttributeName];
			int underlined = [[attributeDict objectForKey:NSUnderlineStyleAttributeName]intValue];
			NSFontTraitMask fontMask = [[NSFontManager sharedFontManager]traitsOfFont:font];
			[[canvasWriter contents]appendFormat:@"ctx.fillStyle=\"%@\";\n",rgba_from_nscolor(col)];
			[[canvasWriter contents] appendString:@"ctx.font = '"];
			if (fontMask & NSBoldFontMask)
				[[canvasWriter contents] appendString:@" bold"];
			if (fontMask & NSItalicFontMask)
				[[canvasWriter contents] appendString:@" italic"];
			if (underlined)
				[[canvasWriter contents] appendString:@" underline"];
			[[canvasWriter contents] appendFormat:@" %gpx %@",[font pointSize],[font familyName]];
			[[canvasWriter contents] appendString:@"';\n"];
			NSString *printString = substitute_characters([[lineString attributedSubstringFromRange:attributeRange]string]);
			[[canvasWriter contents] appendFormat:@"ctx.fillText(\"%@\",%g,%g);\n",printString,glyphLoc.x + b.origin.x,loc.y + b.origin.y + glyphLoc.y];
			i += attributeRange.length;
		}
		glyphIndex += glyphRange.length;
	}

	[[canvasWriter contents]appendString:@"ctx.restore();\n"];
}

-(NSString*)graphicAttributesXML:(NSMutableDictionary*)options
{
    int docHeight = [[options objectForKey:xmlDocHeight]intValue];
    NSMutableString *attrString = [NSMutableString stringWithCapacity:100];
    [attrString appendString:[super graphicAttributesXML:options]];
    NSRect parR = [self parentRect:options];
    NSRect invrect = InvertedRect(parR, docHeight);
    NSRect b = [self bounds];
    NSPoint p0 = b.origin;
    NSPoint p1 = NSMakePoint(NSMaxX(b), NSMaxY(b));
    p0 = InvertedPoint(p0, docHeight);
    p1 = InvertedPoint(p1, docHeight);
    p0 = RelativePointInRect(p0.x,p0.y, invrect);
    p1 = RelativePointInRect(p1.x,p1.y, invrect);
    NSRect r = rectFromPoints(p0, p1);
    [attrString appendFormat:@" x=\"%g\" y=\"%g\" width=\"%g\" height=\"%g\" pxwidth=\"%g\" pxheight=\"%g\"",r.origin.x,r.origin.y,r.size.width,r.size.height,b.size.width,b.size.height];
    /*for (NSArray *arr in self.attributes)
        if ([arr[0]isEqualToString:@"widthtracksheight"] || [arr[0]isEqualToString:@"heighttrackswidth"])
            [attrString appendFormat:@" pxwidth=\"%g\" pxheight=\"%g\"",b.size.width,b.size.height];*/
    if (cornerRadius != 0.0)
        [attrString appendFormat:@" cornerradius=\"%g\"",cornerRadius / b.size.height];
    return attrString;
}

static NSPoint TranslatePointFromRectToRect(NSPoint pt,NSRect r1,NSRect r2)
{
    NSPoint pt1 = LocationForRect(pt.x, pt.y, r1);
    return RelativePointInRect(pt1.x,pt1.y,r2);
}
-(NSString*)graphicXMLForEvent:(NSMutableDictionary*)options
{
    NSMutableString *gString = [NSMutableString stringWithCapacity:200];
    NSString *indent = [options objectForKey:xmlIndent];
    [gString appendFormat:@"%@<text id=\"%@\" %@>\n",indent,self.name,[self graphicAttributesXML:options]];
    [options setObject:[indent stringByAppendingString:@"\t"] forKey:xmlIndent];

    NSRect b = [self bounds],pb = b;
    /*[gString appendFormat:@" translate(%g,%g) scale(1,-1) translate(%g,%g)\">\n",
     b.origin.x,b.origin.y,-b.origin.x,-(b.origin.y + b.size.height)];*/
    //NSTextStorage *cont = [[self layoutManager] textStorage];
    b.origin.x += leftMargin;
    b.size.width -= (leftMargin + rightMargin);
    b.origin.y += topMargin;
    b.size.height -= (topMargin + bottomMargin);
    [[self textContainer] setContainerSize:b.size];
    //NSRange glyphRange = [[self layoutManager] glyphRangeForTextContainer:[self textContainer]];
    if (verticalAlignment != VERTICAL_ALIGNMENT_TOP)
    {
        NSRect r = [[self layoutManager] usedRectForTextContainer:[self textContainer]];
        float diff = b.size.height - r.size.height;
        if (diff > 0.0)
        {
            if (verticalAlignment ==  VERTICAL_ALIGNMENT_BOTTOM)
                b.origin.y += diff;
            else
                b.origin.y += (diff / 2.0);
        }
    }
    [gString appendString:[self tSpansInRect:b relative:YES relativeRect:pb]];
    
    [gString appendFormat:@"%@</text>\n",indent];
    [options setObject:indent forKey:xmlIndent];
    return gString;
}

-(NSString*)tSpansInRect:(NSRect)b relative:(BOOL)relative relativeRect:(NSRect)rr
{
    NSMutableString *tString = [NSMutableString string];
    NSTextStorage *cont = [[self layoutManager] textStorage];
    NSRange glyphRange = [[self layoutManager] glyphRangeForTextContainer:[self textContainer]];
    NSUInteger glyphCount = glyphRange.location + glyphRange.length;
    for (NSUInteger glyphIndex = glyphRange.location;glyphIndex < glyphCount;)
	   {
           NSRect glyphRect = [[self layoutManager] lineFragmentRectForGlyphAtIndex:glyphIndex effectiveRange:&glyphRange];
           NSPoint loc = glyphRect.origin;
           NSAttributedString *lineString = [cont attributedSubstringFromRange:glyphRange];
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
               NSPoint glyphLoc = [[self layoutManager] locationForGlyphAtIndex:glyphRange.location + i];
               NSFont *font = [attributeDict objectForKey:NSFontAttributeName];
               NSColor *col = [attributeDict objectForKey:NSForegroundColorAttributeName];
               int underlined = [[attributeDict objectForKey:NSUnderlineStyleAttributeName]intValue];
               NSFontTraitMask fontMask = [[NSFontManager sharedFontManager]traitsOfFont:font];
               NSPoint pt;
               pt.x = glyphLoc.x + b.origin.x;
               pt.y = loc.y + b.origin.y + glyphLoc.y;
               if (relative)
                   pt = RelativePointInRect(pt.x, pt.y, rr);
               [tString appendFormat:@"<tspan x=\"%g\" y=\"%g\" font-family=\"%@\" font-size=\"%f\"",pt.x,pt.y,[font familyName],[font pointSize]];
               if (fontMask & NSBoldFontMask)
                   [tString appendString:@" font-weight=\"bold\""];
               if (fontMask & NSItalicFontMask)
                   [tString appendString:@" font-style=\"italic\""];
               if (underlined)
                   [tString appendString:@" text-decoration=\"underline\""];
               NSString *printString = substitute_characters([[lineString attributedSubstringFromRange:attributeRange]string]);
               [tString appendFormat:@" fill=\"%@\" >%@</tspan>\n",string_from_nscolor(col),printString];
               i += attributeRange.length;
           }
           glyphIndex += glyphRange.length;
       }
    return tString;
}
-(void)writeSVGData:(SVGWriter*)svgWriter
   {
	[self writeSVGDefs:svgWriter];
	[[svgWriter contents]appendFormat:@"<g id=\"%@\" ",self.name];
//	if (shadowType)
//		[shadowType writeSVGData:svgWriter];
	[[svgWriter contents]appendString:@">\n"];
	if (fill || stroke)
	   {
		[[svgWriter contents]appendFormat:@"<path d=\"%@\" ",string_from_path([self transformedBezierPath])];
		if (fill)
			[fill writeSVGData:svgWriter];
		if (stroke)
			[stroke writeSVGData:svgWriter];
		if (shadowType)
			[shadowType writeSVGData:svgWriter];
		[[svgWriter contents]appendString:@" />\n"];
	   }
	[[svgWriter contents]appendString:@"<text transform=\""];
	if (transform)
		[[svgWriter contents]appendString:string_from_transform(transform)];
	NSRect b = [self bounds];
	[[svgWriter contents]appendFormat:@" translate(%g,%g) scale(1,-1) translate(%g,%g)\">\n",
		b.origin.x,b.origin.y,-b.origin.x,-(b.origin.y + b.size.height)];
	//NSTextStorage *cont = [[self layoutManager] textStorage];
	b.origin.x += leftMargin;
	b.size.width -= (leftMargin + rightMargin);
	b.origin.y += topMargin;
	b.size.height -= (topMargin + bottomMargin);
	[[self textContainer] setContainerSize:b.size];
	//NSRange glyphRange = [[self layoutManager] glyphRangeForTextContainer:[self textContainer]];
	if (verticalAlignment != VERTICAL_ALIGNMENT_TOP)
		{
		NSRect r = [[self layoutManager] usedRectForTextContainer:[self textContainer]];
		float diff = b.size.height - r.size.height;
		if (diff > 0.0)
			{
			if (verticalAlignment ==  VERTICAL_ALIGNMENT_BOTTOM)
				b.origin.y += diff;
			else
				b.origin.y += (diff / 2.0);
			}
		}
//	int glyphCount = [[self layoutManager] numberOfGlyphs];
/*	NSUInteger glyphCount = glyphRange.location + glyphRange.length;
	for (NSUInteger glyphIndex = glyphRange.location;glyphIndex < glyphCount;)
	   {
		NSRect glyphRect = [[self layoutManager] lineFragmentRectForGlyphAtIndex:glyphIndex effectiveRange:&glyphRange];
		NSPoint loc = glyphRect.origin;
		NSAttributedString *lineString = [cont attributedSubstringFromRange:glyphRange];
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
			NSPoint glyphLoc = [[self layoutManager] locationForGlyphAtIndex:glyphRange.location + i];
			NSFont *font = [attributeDict objectForKey:NSFontAttributeName];
			NSColor *col = [attributeDict objectForKey:NSForegroundColorAttributeName];
			int underlined = [[attributeDict objectForKey:NSUnderlineStyleAttributeName]intValue];
			NSFontTraitMask fontMask = [[NSFontManager sharedFontManager]traitsOfFont:font];
			[[svgWriter contents] appendFormat:@"<tspan x=\"%g\" y=\"%g\" font-family=\"%@\" font-size=\"%f\"",
				glyphLoc.x + b.origin.x,loc.y + b.origin.y + glyphLoc.y,[font familyName],[font pointSize]];
			if (fontMask & NSBoldFontMask)
				[[svgWriter contents] appendString:@" font-weight=\"bold\""];
			if (fontMask & NSItalicFontMask)
				[[svgWriter contents] appendString:@" font-style=\"italic\""];
			if (underlined)
				[[svgWriter contents] appendString:@" text-decoration=\"underline\""];
			NSString *printString = substitute_characters([[lineString attributedSubstringFromRange:attributeRange]string]);
			[[svgWriter contents] appendFormat:@" fill=\"%@\" > %@ </tspan>\n",string_from_nscolor(col),printString];
			i += attributeRange.length;
		   }
		glyphIndex += glyphRange.length;
	   }*/
    [[svgWriter contents]appendString:[self tSpansInRect:b relative:NO relativeRect:b]];
    [[svgWriter contents]appendString:@"</text>\n"];
	[[svgWriter contents]appendString:@"</g>\n"];
   }

- (NSRect)boundsWithinMargins
   {
	NSRect b = [self bounds];
	b.origin.x += leftMargin;
	b.origin.y += bottomMargin;
	b.size.width -= (leftMargin + rightMargin);
	b.size.height -= (topMargin + bottomMargin);
	return b;
   }
- (NSSize)sizeOfLaidOutText
   {
	[textContainer setContainerSize:[self boundsWithinMargins].size];
	if (![[[self layoutManager]textContainers]containsObject:textContainer])
		NSLog(@"Container error");
	[[self layoutManager] glyphRangeForTextContainer:[self textContainer]];
	NSRect r = [[self layoutManager] usedRectForTextContainer:[self textContainer]];
	r.size.width += r.origin.x;
	r.size.height += r.origin.y;
	return r.size;
   }

- (NSBezierPath *)clipPath
   {
	return [self pathFromText];
   }

-(NSRect)rectForText
   {
	NSRect b = [self boundsWithinMargins];
	NSSize sz = [self sizeOfLaidOutText];
	if (sz.width > 0.0 && sz.height > 0.0)
	   {
		if (verticalAlignment != VERTICAL_ALIGNMENT_BOTTOM)
		   {
			float diff = b.size.height - sz.height;
			if (diff > 0.0)
			   {
				if (verticalAlignment ==  VERTICAL_ALIGNMENT_TOP)
					b.origin.y += diff;
				else
					b.origin.y += (diff / 2.0);
			   }
		   }
		b.size.height = sz.height;
	   }
	return b;
   }


-(NSRange)characterRangeUnderAdjustedPoint:(NSPoint)pt	//flipped, with container origin at (0,0)
   {
	CGFloat dist;
	NSUInteger glyphIndex = [[self layoutManager] glyphIndexForPoint:pt inTextContainer:[self textContainer] fractionOfDistanceThroughGlyph:&dist];
	NSUInteger charIndex = [[self layoutManager] characterIndexForGlyphAtIndex:glyphIndex];
	return [[[self layoutManager] textStorage] doubleClickAtIndex:charIndex];
   }

-(NSRange)characterRangeUnderPoint:(NSPoint)pt
   {
	NSRect b = [self rectForText];
	if (!NSPointInRect(pt,b))
		return NSMakeRange(0,0);
	pt.x -= b.origin.x;
	pt.y -= b.origin.y;
	pt.y = b.size.height - pt.y;
	return [self characterRangeUnderAdjustedPoint:pt];
   }

-(NSRect)textContainerToRealCoords:(NSRect)r
   {
	NSRect b = [self rectForText];
	r.origin.y = b.size.height - NSMaxY(r);
	r.origin.x += b.origin.x; 
	r.origin.y += b.origin.y;
	return r;
   }

-(NSRect)wordBoundingRectUnderPoint:(NSPoint)pt
   {
	NSRect b = [self rectForText];
	if (!NSPointInRect(pt,b))
		return NSZeroRect;
	pt.x -= b.origin.x;
	pt.y -= b.origin.y;
	pt.y = b.size.height - pt.y;
	NSRange charRange = [self characterRangeUnderAdjustedPoint:pt];
	if (charRange.length == 0)
		return NSZeroRect;
	NSRange glyphRange = [[self layoutManager] glyphRangeForCharacterRange:charRange actualCharacterRange:nil];
	NSRect ob = [[self layoutManager] boundingRectForGlyphRange:glyphRange inTextContainer:[self textContainer]];
	return [self textContainerToRealCoords:ob];
   }

-(NSRange)rangeForAnchor:(int)anchorID
   {
	NSRange charRange = [self characterRange];
	NSUInteger index = charRange.location;
	while (index < charRange.location + charRange.length)
	   {
		NSRange ler;
		id anch = [[[self layoutManager] textStorage]attribute:ACSDAnchorAttributeName atIndex:index longestEffectiveRange:&ler inRange:charRange];
		if (anch && ([anch intValue] == anchorID))
			return ler;
		index = ler.location + ler.length;
	   }
	return NSMakeRange(NSNotFound,NSNotFound);
   }

-(void)drawHighlightRect:(NSRect)r colour:(NSColor*)col anchorID:(int)anchorID overflow:(BOOL)ov
   {
	NSRange anchorRange = [self rangeForAnchor:anchorID];
	if (anchorRange.location != NSNotFound)
		[self drawHighlightRect:r colour:col charRange:anchorRange];
   }

-(void)drawHighlightRect:(NSRect)r colour:(NSColor*)col charRange:(NSRange)charRange
   {
	NSRange glyphRange = [[self layoutManager] glyphRangeForCharacterRange:charRange actualCharacterRange:nil];
	NSRect b = [[self layoutManager] boundingRectForGlyphRange:glyphRange inTextContainer:[self textContainer]];
	b = [self textContainerToRealCoords:b];
	if (!NSEqualRects(b,NSZeroRect))
	   {
		NSBezierPath *p = [NSBezierPath bezierPathWithRect:b];
		[[NSColor colorWithCalibratedRed:[col redComponent] green:[col greenComponent] blue:[col blueComponent] alpha:0.5] set];
		[p fill];
		return;
	   }
   }

-(void)drawHighlightRect:(NSRect)r colour:(NSColor*)col hotPoint:(NSPoint)hotPoint modifiers:(NSUInteger)modifiers
   {
	if ((modifiers & NSCommandKeyMask) == 0)
		{
		NSRect b = [self bounds];
		b = NSInsetRect(b,4,4);
		if (NSPointInRect(hotPoint,b))
		   {
			b = [self wordBoundingRectUnderPoint:hotPoint];
			if (!NSEqualRects(b,NSZeroRect))
			   {
				NSBezierPath *p = [NSBezierPath bezierPathWithRect:b];
				[[NSColor colorWithCalibratedRed:[col redComponent] green:[col greenComponent] blue:[col blueComponent] alpha:0.5] set];
				[p fill];
				return;
			   }
		   }
	}
	[super drawHighlightRect:r colour:col hotPoint:hotPoint modifiers:modifiers];
   }

-(void)setMayContainSubstitutions:(BOOL)b
   {
    mayContainSubstitutions = b;
   }

-(void)deleteLinksInRange:(NSRange)charRange
   {
	NSTextStorage *storage = [[self layoutManager] textStorage];
	NSUInteger index = charRange.location;
	while (index < charRange.location + charRange.length)
	   {
		NSRange resultRange;
		if (id l = [storage attribute:NSLinkAttributeName atIndex:index longestEffectiveRange:&resultRange inRange:charRange])
			if ([l isKindOfClass:[ACSDLink class]])
				[ACSDLink uDeleteFromFromObjectLink:l undoManager:[self undoManager]];
		index = resultRange.location + resultRange.length;
	   }
   }

- (BOOL)uUnlinkText
   {
	if ([self previousText])
	   {
		[[[self undoManager] prepareWithInvocationTarget:self] uLinkToText:[self previousText]];
		[self unlinkFromText];
		return YES;
	   }
	else if ([self nextText])
	   {
	    while ([self nextText])
			[[self nextText]uUnlinkText];
		return YES;
	   }
	return NO;
   }

- (BOOL)uLinkToText:(ACSDText*)sText
   {
	if (![self previousText] && ![self nextText])
	   {
		[[[self undoManager] prepareWithInvocationTarget:self] uUnlinkText];
		[self linkToText:sText];
		return YES;
	   }
	return NO;
   }

-(void)preDelete
   {
	if (link)
		[ACSDLink uDeleteLinkForObject:self undoManager:[self undoManager]];
	if (linkedObjects)
	   {
		NSSet *lo = [[linkedObjects copy]autorelease];
		for (ACSDLink *l in lo)
			[ACSDLink uDeleteFromFromObjectLink:l undoManager:[self undoManager]];
	   }
	if (!previousText && !nextText)
		[self deleteLinksInRange:[self characterRange]];
	[self uUnlinkText];
	[self setDeleted:YES];
   }

-(NSRange)removeTextLink:(ACSDLink*)lnk
   {
	NSTextStorage *storage = [[self layoutManager] textStorage];
	NSRange charRange = [self characterRange];
	NSUInteger index = charRange.location;
	while (index < charRange.location + charRange.length)
	   {
		NSRange resultRange;
		if (id l = [storage attribute:NSLinkAttributeName atIndex:index longestEffectiveRange:&resultRange inRange:charRange])
		   {
			if (l && l == lnk)
			   {
				[storage beginEditing];
				[storage removeAttribute:NSLinkAttributeName range:resultRange];
				[storage endEditing];
				return resultRange;
			   }
		   }
		index = resultRange.location + resultRange.length;
	   }
	return NSMakeRange(NSNotFound,NSNotFound);
   }

-(BOOL)fixTextSubstitutionsFromDictionary:(NSDictionary*)substitutions range:(NSRange)charRange
   {
	BOOL didSomething = NO;
	NSTextStorage *storage = [[self layoutManager] textStorage];
	NSUInteger index = charRange.location;
	while (index < charRange.location + charRange.length)
	   {
		NSRange resultRange;
		if (id textSub = [storage attribute:TextSubstitutionAttribute atIndex:index effectiveRange:&resultRange])
		   {
			if (textSub)
			   {
				NSString *contentsSubstring = [[storage string]substringWithRange:resultRange];
				NSString *substitutionString = [textSub substitutedValueFromDictionary:substitutions];
				if (![contentsSubstring isEqualToString:substitutionString])
				   {
					//NSLog(@"Substituting *%@* for *%@*",substitutionString,contentsSubstring);
					[storage beginEditing];
					[storage replaceCharactersInRange:resultRange withString:substitutionString];
					[storage endEditing];
					charRange.length += ([substitutionString length] - [contentsSubstring length]);
					didSomething = YES;
				   }
			   }
		   }
		index = resultRange.location + resultRange.length;
	   }
	index = charRange.location;
	while (index < charRange.location + charRange.length)
	   {
		NSRange resultRange;
		if (id lnk = [storage attribute:NSLinkAttributeName atIndex:index longestEffectiveRange:&resultRange inRange:charRange])
			if ([lnk isKindOfClass:[ACSDLink class]] && [lnk substitutePageNo])
			   {
				NSString *contentsSubstring = [[storage string]substringWithRange:resultRange];
				NSString *substitutionString = [NSString stringWithFormat:@"%ld",[lnk pageNumberForToObject]];
				if (![contentsSubstring isEqualToString:substitutionString])
				   {
					//NSLog(@"Substituting *%@* for *%@*",substitutionString,contentsSubstring);
					[storage beginEditing];
					[storage replaceCharactersInRange:resultRange withString:substitutionString];
					[storage endEditing];
					charRange.length += ([substitutionString length] - [substitutionString length]);
					didSomething = YES;
				   }
			   }
		index = resultRange.location + resultRange.length;
	   }
	return didSomething;
   }

-(BOOL)mayContainSubstitutions
   {
    return mayContainSubstitutions;
   }

- (void)drawObject:(NSRect)aRect view:(GraphicView*)gView options:(NSMutableDictionary*)options
   {
	[NSGraphicsContext saveGraphicsState];
	NSBezierPath *path = [self bezierPath];
	if (isMask)
	   {
		NSBezierPath *clipPath = [self bezierPath];
		[clipPath appendBezierPath:[self pathFromText]];
		[clipPath addClip];
	   }
	if (fill)
		[fill fillPath:path];
	if ([gView drawingToPDF])
	   {
		if ([[ACSDPrefsController sharedACSDPrefsController:nil]pdfLinkMode] == PDF_LINK_COLOUR)
			[self addTextLinksForPDFContext:[gView drawingToPDF]];
	   }
	if (stroke)
		[stroke strokePath:path];
	[NSGraphicsContext saveGraphicsState];
    if (!(([gView editingGraphic] == self) || ([gView creatingGraphic] == self) || isMask))
	   {
//		if (![self visible])
//			return;
		if ([[[self layoutManager] textStorage] length] > 0)
		   {
			NSRect b = [self rectForText];
			if (b.size.width > 0.0 && b.size.height > 0.0)
			   {
				NSRange glyphRange, charRange;
				if (drawingToCache || (currentDrawingDestination && [currentDrawingDestination isMemberOfClass:[NSImage class]]))
				   {
					NSImage *im = [[NSImage alloc]initWithSize:NSMakeSize(b.size.width*[self magnification],
																		  b.size.height*[self magnification])];
					//[im setFlipped:YES];
					[im lockFocusFlipped:YES];
					if ([self magnification] != 1.0)
					   {
						NSAffineTransform *tf = [NSAffineTransform transform];
						[tf scaleBy:[graphicCache magnification]];
						[tf concat];
					   }
					glyphRange = [[self layoutManager] glyphRangeForTextContainer:[self textContainer]];
					charRange = [[self layoutManager] characterRangeForGlyphRange:glyphRange actualGlyphRange:nil];
					if ([self fixTextSubstitutionsFromDictionary:[options objectForKey:@"substitutions"] range:charRange])
					   {
						glyphRange = [[self layoutManager] glyphRangeForTextContainer:[self textContainer]];
						charRange = [[self layoutManager] characterRangeForGlyphRange:glyphRange actualGlyphRange:nil];
						[self setMayContainSubstitutions:YES];
					   }
					overflow = [[[self layoutManager] textStorage] length] > charRange.location + charRange.length;
					if (glyphRange.length > 0)
					   {
						[[self layoutManager] drawBackgroundForGlyphRange:glyphRange atPoint:NSMakePoint(0,0)];
						[[self layoutManager] drawGlyphsForGlyphRange:glyphRange atPoint:NSMakePoint(0,0)];
					   }
					[im unlockFocus];
					[im drawInRect:b fromRect:NSMakeRect(0,0,[im size].width,[im size].height) operation:NSCompositeSourceOver fraction:1.0];
					[im release];
				   }
				else
				   {
					glyphRange = [[self layoutManager] glyphRangeForTextContainer:[self textContainer]];
					charRange = [[self layoutManager] characterRangeForGlyphRange:glyphRange actualGlyphRange:nil];
					//NSLog(@"glyphRange before  fix %d %d %d",glyphRange.location,glyphRange.length,[[[[self layoutManager] textStorage]string]length]);
					if ([self fixTextSubstitutionsFromDictionary:[options objectForKey:@"substitutions"] range:charRange])
					   {
						glyphRange = [[self layoutManager] glyphRangeForTextContainer:[self textContainer]];
						charRange = [[self layoutManager] characterRangeForGlyphRange:glyphRange actualGlyphRange:nil];
						[self setMayContainSubstitutions:YES];
					   }
					overflow = [[[self layoutManager] textStorage] length] > charRange.location + charRange.length;
//					BOOL flipped = [[self currentDrawingDestination]isFlipped];
					BOOL flipped = [[NSView focusView]isFlipped];
					int linkMode = 0;
					if ([gView drawingToPDF])
						linkMode =  [[ACSDPrefsController sharedACSDPrefsController:nil]pdfLinkMode];
					[NSGraphicsContext saveGraphicsState];
//					[[self currentDrawingDestination]setFlipped:YES];
					if ([[NSView focusView] respondsToSelector:@selector(setFlipped:)])
						[(id)[NSView focusView]setFlipped:YES];
					NSAffineTransform *tr = [NSAffineTransform transform];
					[tr translateXBy:b.origin.x yBy:b.origin.y + b.size.height];
					[tr scaleXBy:1.0 yBy:-1.0];
					[tr concat];
					NSAttributedString *strCopy = nil;
					BOOL textChanged = NO;
					if (linkMode & PDF_LINK_TEXT_COLOUR)
					   {
						NSDictionary *aDict = [NSDictionary dictionaryWithObject:[[ACSDPrefsController sharedACSDPrefsController:nil]pdfLinkHighlightColour] forKey:NSForegroundColorAttributeName];
						strCopy = [[[self layoutManager] textStorage]attributedSubstringFromRange:charRange];
						NSUInteger index = charRange.location;
						while (index < charRange.location + charRange.length)
						   {
							NSRange resultRange;
							id lnk = [[[self layoutManager] textStorage] attribute:NSLinkAttributeName atIndex:index longestEffectiveRange:&resultRange inRange:charRange];
							if (lnk && [lnk changeAttributes])
							   {
								[[[self layoutManager] textStorage]addAttributes:aDict range:resultRange];
								textChanged = YES;
							   }
							index = NSMaxRange(resultRange);
						   }
						[[self layoutManager] glyphRangeForTextContainer:[self textContainer]];
						//NSLog(@"glyphRange before %d %d %d",rr.location,rr.length,[[[[self layoutManager] textStorage]string]length]);
					   }
					if (glyphRange.length > 0)
					   {
						[[self layoutManager] drawBackgroundForGlyphRange:glyphRange atPoint:NSMakePoint(0,0)];
						[[self layoutManager] drawGlyphsForGlyphRange:glyphRange atPoint:NSMakePoint(0,0)];
					   }
					if ((linkMode & PDF_LINK_TEXT_COLOUR) && textChanged)
					   {
						[[[self layoutManager]textStorage]beginEditing];
						[[[self layoutManager]textStorage]replaceCharactersInRange:charRange withAttributedString:strCopy];
						[[[self layoutManager]textStorage]endEditing];
					   }
//					[[self currentDrawingDestination] setFlipped:flipped];
					if ([[NSView focusView] respondsToSelector:@selector(setFlipped:)])
						[(id)[NSView focusView]setFlipped:flipped];
					[NSGraphicsContext restoreGraphicsState];
				   }
			   }
           }
        }
	[NSGraphicsContext restoreGraphicsState];
	if ([gView drawingToPDF])
	   {
		if ([[ACSDPrefsController sharedACSDPrefsController:nil]pdfLinkMode] == PDF_LINK_STROKE)
			[self addTextLinksForPDFContext:[gView drawingToPDF]];
	   }
	[NSGraphicsContext restoreGraphicsState];
   }
	
- (void)startEditingWithEvent:(NSEvent *)event inView:(GraphicView *)view
   {
    NSTextView *editor = [view editor];
    NSRect b = [self boundsWithinMargins];
	[[self textContainer] setTextView:editor];
	[[self textContainer] setContainerSize:b.size];
	NSPoint pt = b.origin;
    b.origin.x += (b.size.width/2.0);
    b.origin.y += (b.size.height/2.0);
	NSAffineTransform *trans = [NSAffineTransform transform];
	[trans translateXBy:b.origin.x yBy:b.origin.y];
	[trans rotateByDegrees:rotation];
	[trans translateXBy:-b.origin.x yBy:-b.origin.y];
	pt = [trans transformPoint:pt];
	[editor setFrame:b];
	[editor setFrameRotation:rotation];
	[editor setFrameOrigin:pt];
//    [cont addLayoutManager:[editor layoutManager]];
    [view addSubview:editor];
    [view setEditingGraphic:self];
    [editor setSelectedRange:NSMakeRange(0, [contents length])];
       editor.selectedTextAttributes = @{NSForegroundColorAttributeName:[NSColor blackColor],
                                         NSBackgroundColorAttributeName:[[NSColor blueColor]colorWithAlphaComponent:0.3]
       };
	if ([contents length] == 0)
		[editor setTypingAttributes:[[[StyleWindowController sharedStyleWindowController]currentStyle]textAndStyleAttributes]];
    [editor setDelegate:self];
	[editor setImportsGraphics:YES];
    // Make sure we redisplay
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:YES notify:NO];

    [[view window] makeFirstResponder:editor];
    if (event)
        [editor mouseDown:event];
   }

- (void)endEditingInView:(GraphicView *)view
   {
    if ([view editingGraphic] == self)
	   {
        NSTextView *editor = (NSTextView *)[view editor];
		[[self textContainer] setTextView:nil];
        [editor setDelegate:nil];
        [editor removeFromSuperview];
		[view setEditorInUse:NO];
        [view setEditingGraphic:nil];
		[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:YES notify:NO];
		[[view window] makeFirstResponder:view];
       }
   }

- (void)layoutManager:(NSLayoutManager *)aLayoutManager didCompleteLayoutForTextContainer:(NSTextContainer *)aTextContainer atEnd:(BOOL)flag
   {
	NSTextView *textView = [aTextContainer textView];
	GraphicView *gView = (GraphicView*)[textView superview];
	if (gView)
		return;
   }

-(NSDictionary*)textView:(NSTextView*)textView shouldChangeTypingAttributes:(NSDictionary*)oldTypingAttributes toAttributes:(NSDictionary*)newTypingAttributes
   {
	return newTypingAttributes;
   }

- (void)textDidChange:(NSNotification *)aNotification					//	NSText
   {
	NSRange charRange = [self characterRange];
	BOOL ovf = [[[self layoutManager] textStorage] length] > charRange.location + charRange.length;
	if (ovf != overflow)
	   {
		overflow = ovf;
	   }
   }

- (void)textViewDidChangeSelection:(NSNotification *)aNotification
   {
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDGraphicViewTextSelectionDidChangeNotification object:self];
   }

-(void)copyToPasteBoardForTextView:(NSTextView*)textView
   {
	NSArray *selectedRanges = [textView selectedRanges];
	NSUInteger count;
	if ((count = [selectedRanges count]) == 0)
		return;
	if (count == 1)
	   {
		NSRange r = [[selectedRanges objectAtIndex:0]rangeValue];
		if (r.length == 0)
			return;
	   }
    [[NSPasteboard generalPasteboard] declareTypes:[NSArray arrayWithObjects:NSRTFDPboardType,ACSDrawTextPBoardType,nil] owner:self];
	NSData *data = [textView RTFDFromRange:[[selectedRanges objectAtIndex:0]rangeValue]];
	[[NSPasteboard generalPasteboard] setData:data forType:NSRTFDPboardType];
	[[NSPasteboard generalPasteboard] setData:data forType:ACSDrawTextPBoardType];
   }

- (BOOL)textView:(NSTextView *)aTextView doCommandBySelector:(SEL)aSelector
   {
	if (aSelector == @selector(copy:))
	   {
		[self copyToPasteBoardForTextView:aTextView];
		return YES;
	   }
	return NO;
   }

- (NSBezierPath *)bezierPath
{
	if (cornerRadius == 0.0)
		return [NSBezierPath bezierPathWithRect:bounds];
	NSBezierPath *path = [NSBezierPath bezierPath];
	NSRect iBounds = NSInsetRect(bounds,cornerRadius,cornerRadius);
	[path moveToPoint:NSMakePoint(bounds.origin.x,iBounds.origin.y)];
	[path appendBezierPathWithArcWithCenter:iBounds.origin radius:cornerRadius startAngle:180.0 endAngle:270.0 clockwise:NO];
	[path lineToPoint:NSMakePoint(NSMaxX(iBounds),bounds.origin.y)];
	[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(iBounds),NSMinY(iBounds)) radius:cornerRadius startAngle:270.0 endAngle:0.0 clockwise:NO];
	[path lineToPoint:NSMakePoint(NSMaxX(bounds),NSMaxY(iBounds))];
	[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(iBounds),NSMaxY(iBounds)) radius:cornerRadius startAngle:0.0 endAngle:90.0 clockwise:NO];
	[path lineToPoint:NSMakePoint(NSMinX(iBounds),NSMaxY(bounds))];
	[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(iBounds),NSMaxY(iBounds)) radius:cornerRadius startAngle:90.0 endAngle:180.0 clockwise:NO];
	[path closePath];
    return path;
}

-(BOOL)isSameAs:(id)obj
   {
	if (![super isSameAs:obj])
		return NO;
	if (!(topMargin==[(ACSDText*)obj topMargin]&& leftMargin == [(ACSDText*)obj leftMargin] && bottomMargin == [(ACSDText*)obj bottomMargin] && rightMargin == [(ACSDText*)obj rightMargin]))
		return NO;
	return [contents isEqual:[((ACSDText*)obj) contents]];
   }

-(void)setBoundsTo:(NSRect)newBounds from:(NSRect)oldBounds 
   { 
	[super setBoundsTo:newBounds from:oldBounds];
	[[self textContainer] setContainerSize:newBounds.size];
   }
/*
-(void)setGraphicBoundsTo:(NSRect)newBounds from:(NSRect)oldBounds 
   {
	[super setGraphicBoundsTo:newBounds from:oldBounds];
	[[self textContainer] setContainerSize:newBounds.size];
   }
*/
-(BOOL)setGraphicBoundsTo:(NSRect)newBounds from:(NSRect)oldBounds 
{
    if (NSEqualRects(newBounds, oldBounds))
		return NO;
	else
	{
		[super setGraphicBoundsTo:newBounds from:oldBounds];
		if (cornerRadius != 0.0 || (manipulatingBounds && originalCornerRadius != 0.0))
		{
			float ratio=0.0,smallSide;
			if (manipulatingBounds)
			{
				ratio = originalCornerRatio;
			}
			else
			{
				smallSide = fmin(oldBounds.size.width,oldBounds.size.height);
				if (smallSide != 0.0)
				{
					ratio = cornerRadius/smallSide;
				}
			}
			smallSide = fmin(newBounds.size.width,newBounds.size.height);
			float newCornerRadius = ratio * smallSide;
			//			[self setGraphicCornerRadius:newCornerRadius notify:YES];
			[self setCornerRadius:newCornerRadius];
		}
		[[self textContainer] setContainerSize:newBounds.size];
		return YES;
	}
}

- (NSRect)preFlowRectMagnification:(float)mag
   {
    NSRect b = [self bounds];
	NSPoint upperLeft = b.origin;
	upperLeft.y += (b.size.height - 2 * ACSD_HANDLE_WIDTH);
	float handleWidth = ACSD_HANDLE_WIDTH / mag;
	upperLeft.x -= handleWidth;
	upperLeft.y -= handleWidth;
	NSRect r;
	r.origin = upperLeft;
	r.size.width = r.size.height = handleWidth * 2;
	return r;
   }

- (NSRect)postFlowRectMagnification:(float)mag
   {
    NSRect b = [self bounds];
	float handleWidth = ACSD_HANDLE_WIDTH / mag;
	NSRect r;
	NSPoint bottomRight = b.origin;
	bottomRight.x += b.size.width;
	bottomRight.y += (2 * ACSD_HANDLE_WIDTH);
	bottomRight.x -= handleWidth;
	bottomRight.y -= handleWidth;
	r.origin = bottomRight;
	r.size.width = r.size.height = handleWidth * 2;
 	return r;
   }

-(NSBezierPath*)crossInRect:(NSRect)r
   {
	NSBezierPath *path = [NSBezierPath bezierPath];
	float midX = r.origin.x + r.size.width / 2.0;
	float midY = r.origin.y + r.size.height / 2.0;
	[path moveToPoint:NSMakePoint(r.origin.x + 2.0,midY)];
	[path lineToPoint:NSMakePoint(r.origin.x + r.size.width - 2.0,midY)];
	[path moveToPoint:NSMakePoint(midX,r.origin.y + 2.0)];
	[path lineToPoint:NSMakePoint(midX,r.origin.y + r.size.height - 2.0)];
	return path;
   }

- (void)drawOtherHandlesMagnification:(float)mag
   {
	[NSGraphicsContext saveGraphicsState];
	if (transform)
		[transform concat];
	NSRect r = [self preFlowRectMagnification:mag];
	[[NSColor whiteColor]set];
	NSRectFill(r);
	[[NSColor cyanColor] set];
	[NSBezierPath setDefaultLineWidth:0.0];
	[NSBezierPath strokeRect:r];
	if (previousText)
	   {
		[[NSColor cyanColor] set];
		[[self crossInRect:r]stroke];
	   }
	r = [self postFlowRectMagnification:mag];
	[[NSColor whiteColor]set];
	NSRectFill(r);
	[[NSColor cyanColor] set];
	[NSBezierPath strokeRect:r];
	if (nextText)
	   {
		[[NSColor cyanColor] set];
		[[self crossInRect:r]stroke];
	   }
	else if (overflow)
	   {
		[[NSColor redColor] set];
		[[self crossInRect:r]stroke];
	   }
	[NSGraphicsContext restoreGraphicsState];
   }

- (KnobDescriptor)knobUnderPoint:(NSPoint)point view:(GraphicView*)gView
   {
	KnobDescriptor kd = [super knobUnderPoint:point view:gView];
	if (kd.knob != NoKnob)
		return kd;
	if (NSPointInRect(point,[self preFlowRectMagnification:[gView magnification]]))
		return KnobDescriptor(previousTextKnob);
	if (NSPointInRect(point,[self postFlowRectMagnification:[gView magnification]]))
		return KnobDescriptor(nextTextKnob);
    return KnobDescriptor(NoKnob);
   }

-(ACSDText*)nextText
   {
	return nextText;
   }

-(ACSDText*)previousText
   {
	return previousText;
   }

-(void)setNextText:(ACSDText*)nt
   {
	nextText = nt;
   }

-(void)setPreviousText:(ACSDText*)pt
   {
	previousText = pt;
   }

- (void)unlinkFromText
   {
	if (!previousText)
		return;
	NSUInteger i = [[[self layoutManager] textContainers]indexOfObjectIdenticalTo:[self textContainer]];
	[[self layoutManager] removeTextContainerAtIndex:i];
	[previousText setNextText:nextText];
	[nextText setPreviousText:previousText];
	ACSDText *nt = nextText;
	nextText = nil;
	previousText = nil;
//	contents = [[ACSDTextStorage allocWithZone:[self zone]] init];
	contents = [[NSTextStorage allocWithZone:[self zone]] init];
	[self allocateTextSystemStuff];
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:YES notify:NO];
	[nt invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:YES notify:NO];
   }

- (void)linkToText:(ACSDText*)pt
   {
	[self setContents:nil];
	nextText = [pt nextText];
	[pt setNextText:self];
	previousText = pt;
    layoutManager = [previousText layoutManager];
    textContainer = [[ACSDTextContainer allocWithZone:NULL] initWithContainerSize:bounds.size graphic:self];
	NSUInteger i = [[[self layoutManager] textContainers]indexOfObjectIdenticalTo:[previousText textContainer]];
    [[self layoutManager] insertTextContainer:[textContainer autorelease]atIndex:i + 1];
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:YES notify:NO];
   }

-(void)setObjectsInFrontValid:(BOOL)b
   {
	objectsInFrontValid = b;
	if (b == NO)
		[self setObjectsInTheWayValid:NO];
   }

-(void)setObjectsInTheWayValid:(BOOL)b
   {
	objectsInTheWayValid = b;
	if (b == NO)
		[self setPathInTheWayValid:NO];
   }

-(void)setPathInTheWayValid:(BOOL)b
   {
	pathInTheWayValid = b;
   }

-(BOOL)objectsInFrontValid
   {
	return objectsInFrontValid;
   }

-(BOOL)objectsInTheWayValid
   {
	return objectsInTheWayValid;
   }

-(BOOL)pathInTheWayValid
   {
	return pathInTheWayValid;
   }

-(NSSet*)objectsInFront
   {
	if (objectsInFrontValid)
		return objectsInFront;
	if (objectsInFront == nil)
		objectsInFront = [[NSMutableSet setWithCapacity:10]retain];
	else
		[objectsInFront removeAllObjects];
	[layer addGraphicsInFrontOfGraphic:self toSet:objectsInFront];
	objectsInFrontValid = YES;
	return objectsInFront;
   }


-(ACSDPath*)pathInTheWay
   {
	if (pathInTheWayValid)
		return pathInTheWay;
	NSArray *objs = [[self objectsInTheWay]allObjects];
	NSUInteger ct = [objs count];
	NSMutableArray *pathArray = [NSMutableArray arrayWithCapacity:ct];
	for (int i = 0;i < ct;i++)
	   {
/*	    id g = [objs objectAtIndex:i];
		if ([g isMemberOfClass:[ACSDPath class]])
			g = [[g copy]autorelease];
		else
			g = [g convertToPath];
		[g applyTransform];
		[pathArray addObject:g];*/
		[pathArray addObject:[[objs objectAtIndex:i] wholeOutline]];
	   }
	pathInTheWay = [[ACSDSubPath unionPathFromPaths:pathArray]retain];
	pathInTheWayValid = true;
	return pathInTheWay;	
   }
	
-(NSSet*)objectsInTheWay
   {
	if (objectsInTheWayValid)
		return objectsInTheWay;
	if (objectsInTheWay == nil)
		objectsInTheWay = [[NSMutableSet setWithCapacity:10]retain];
	else
		[objectsInTheWay removeAllObjects];
    NSEnumerator *oEnum = [[self objectsInFront] objectEnumerator];
    ACSDGraphic *o;
	NSRect r = [self transformedBounds];
    while ((o = [oEnum nextObject]) != nil)
        if (NSIntersectsRect(r, [o displayBounds]))
			[objectsInTheWay addObject:o];
	objectsInTheWayValid = YES;
	return objectsInTheWay;
   }

-(NSLayoutManager*)layoutManager
   {
	if (layoutManager)
		return layoutManager;
	if (previousText)
	   {
		layoutManager = [previousText layoutManager];
		return layoutManager;
	   }
    layoutManager = [[NSLayoutManager allocWithZone:NULL] init];
//    textContainer = [[ACSDTextContainer allocWithZone:NULL] initWithContainerSize:bounds.size graphic:self];
    [layoutManager addTextContainer:[self textContainer]];
	[layoutManager setDelegate:self];
	overflow = NO;
	return layoutManager;
   }

-(NSTextContainer*)textContainer
   {
    if (textContainer == nil)
		textContainer = [[[ACSDTextContainer allocWithZone:NULL] initWithContainerSize:bounds.size graphic:self]autorelease];
	return textContainer;
   }

-(BOOL)isTextObject
   {
	return YES;
   }

-(void)uSetFont:(NSFont*)font forRange:(NSRange)r oldFont:(NSFont*)oldfont
{
	[[[self undoManager] prepareWithInvocationTarget:self] uSetFont:oldfont forRange:r oldFont:font];
	[[layoutManager textStorage]setAttributes:[NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName] range:r];
}

-(void)uScale:(float)sc pointSizeInRange:(NSRange)r
{
	NSFont *f = [[layoutManager textStorage] attribute:NSFontAttributeName atIndex:r.location effectiveRange:NULL];
	NSFont *fnew = [[NSFontManager sharedFontManager]convertFont:f toSize:[f pointSize] * sc];
	[self uSetFont:fnew forRange:r oldFont:f];
}

-(void)scaleFontsBy:(CGFloat)sc
{
    NSTextStorage *textStorage = [layoutManager textStorage];
    if ([[self textContainer] textView])
    {
        NSArray<NSValue*>*ranges= [[[self textContainer] textView]selectedRanges];
        if ([ranges count] > 0)
        {
            for (NSValue *v in ranges)
            {
                NSRange r = [v rangeValue];
                [textStorage enumerateAttribute:NSFontAttributeName inRange:r options:0
                                     usingBlock:^void (id value,NSRange r,BOOL *stop){[self uScale:sc pointSizeInRange:r];}];
            }
            return;
        }
    }
    [textStorage beginEditing];
    [textStorage enumerateAttribute:NSFontAttributeName inRange:NSMakeRange(0,[textStorage length]) options:0
                         usingBlock:^void (id value,NSRange r,BOOL *stop){[self uScale:sc pointSizeInRange:r];}];
    [textStorage endEditing];
}

-(void)permanentScale:(float)sc transform:(NSAffineTransform*)t
{
	[super permanentScale:sc transform:t];
	if (!layoutManager)
		return;
    [self scaleFontsBy:sc];
}

-(void)processAttributesInRange:(NSRange)totalRange forStyle:(ACSDStyle*)style oldAttributes:(NSDictionary*)oldAttrs
   {
	NSRange longestRange;
	NSUInteger index = totalRange.location;
	while (index < totalRange.location + totalRange.length)
	   {
		NSDictionary *textAttrs = [[[self layoutManager] textStorage] attributesAtIndex:index longestEffectiveRange:&longestRange inRange:totalRange];
		NSDictionary *existingAttrs = [ACSDStyle attributesFromTypingAttributes:textAttrs];
		NSDictionary *diff = [ACSDStyle attributesFrom:existingAttrs differingFrom:oldAttrs];
		diff = [ACSDStyle attributesFrom:[style attributes] notIn:diff];
		NSDictionary *diffAttrs = [ACSDStyle typingAttributesFromAttributes:diff existingAttributes:existingAttrs existingParagraphStyle:[textAttrs objectForKey:NSParagraphStyleAttributeName]];
		[[[self layoutManager] textStorage] addAttributes:diffAttrs range:longestRange];
		index = longestRange.location + longestRange.length;
	   }
   }


-(void)updateRange:(NSRange)allRange forNewStyle:(ACSDStyle*)newStyle		//done to a paragraph when a new style is selected
  {
	NSRange longestRange;
	NSUInteger index = allRange.location;
	NSDictionary *styleAttr=[NSDictionary dictionaryWithObject:newStyle forKey:StyleAttribute];
	[[[self layoutManager] textStorage] beginEditing];
	while (index < allRange.location + allRange.length)
	   {
		ACSDStyle *st = [[[self layoutManager] textStorage] attribute:StyleAttribute atIndex:index longestEffectiveRange:&longestRange inRange:allRange];
		NSDictionary *oldAttrs = (st)?[st attributes]:nil;
		if ([newStyle nullStyle])
			[[[self layoutManager] textStorage] removeAttribute:StyleAttribute range:longestRange];
		else
			[[[self layoutManager] textStorage] addAttributes:styleAttr range:longestRange];
		[self processAttributesInRange:longestRange forStyle:newStyle oldAttributes:oldAttrs];
		index = longestRange.location + longestRange.length;
	   }
	[[[self layoutManager] textStorage] endEditing];
  }

-(void)forceUpdateRange:(NSRange)allRange forStyle:(ACSDStyle*)style
   {
	[[[self layoutManager] textStorage] beginEditing];
	[[[self layoutManager] textStorage] addAttributes:[style textAndStyleAttributes] range:allRange];
	[[[self layoutManager] textStorage] endEditing];
   }

-(void)updateForStyle:(ACSDStyle*)style oldAttributes:(NSDictionary*)oldAttrs
   {
	NSRange longestRange,allRange;
	allRange.location = 0;
	allRange.length = [contents length];
	BOOL begunEditing = NO;
	NSUInteger index = 0;
	NSDictionary *styleAttr=nil;
	while (index < allRange.length)
	   {
		ACSDStyle *st = [[[self layoutManager] textStorage] attribute:StyleAttribute atIndex:index longestEffectiveRange:&longestRange inRange:allRange];
		if (st && st == style)
		   {
			if (!begunEditing)
			   {
				begunEditing = YES;
				[[[self layoutManager] textStorage] beginEditing];
				styleAttr = [NSDictionary dictionaryWithObject:style forKey:StyleAttribute];
			   }
			[[[self layoutManager] textStorage] addAttributes:styleAttr range:longestRange];
			[self processAttributesInRange:longestRange forStyle:st oldAttributes:oldAttrs];
//			[[[self layoutManager] textStorage] addAttributes:attributes range:longestRange];
		   }
		index = longestRange.location + longestRange.length;
	   }
	if (begunEditing)
		[[[self layoutManager] textStorage] endEditing];
   }

NSAttributedString* stripWhiteSpaceFromAttributedString(NSAttributedString* mas)
   {
	NSString *str = [mas string];
	NSInteger len = [str length],stInd=0,endInd=len - 1;
	NSCharacterSet *chSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	while (stInd < len && [chSet characterIsMember:[str characterAtIndex:stInd]])
		stInd++;
	while (endInd >= 0 && [chSet characterIsMember:[str characterAtIndex:endInd]])
		endInd--;
	if (endInd >= stInd)
		return [mas attributedSubstringFromRange:NSMakeRange(stInd,endInd-stInd+1)];
	return nil;
   }

-(void)addTOCStyles:(NSArray*)styles toString:(NSMutableAttributedString*)tocString mappedStyles:(NSArray*)mappedStyles target:(ACSDText*)target
   {
	NSRange longestRange,allRange;
	allRange = [self characterRange];
	NSUInteger index = allRange.location;
	while (index < allRange.location + allRange.length)
	   {
		ACSDStyle *st = [[[self layoutManager] textStorage] attribute:StyleAttribute atIndex:index longestEffectiveRange:&longestRange inRange:allRange];
		if (st)
		   {
			NSUInteger i = [styles indexOfObjectIdenticalTo:st];
			if (i != NSNotFound)
			   {
				ACSDStyle* style = [mappedStyles objectAtIndex:i];
				NSAttributedString *as = [[[self layoutManager] textStorage] attributedSubstringFromRange:longestRange];
				if ([[as string]length] > 0)
				   {
					as = stripWhiteSpaceFromAttributedString(as);
					if (as)
					   {
						NSMutableAttributedString *mas = [[as mutableCopy]autorelease];
						[mas beginEditing];
						[mas removeAttribute:StyleAttribute range:NSMakeRange(0,[[as string]length])];
						[mas removeAttribute:NSLinkAttributeName range:NSMakeRange(0,[[as string]length])];
						int anchor = [self assignAnchorForRange:longestRange];
						ACSDLink *l = [ACSDLink linkFrom:target to:self anchorID:anchor substitutePageNo:NO changeAttributes:NO];
						[mas addAttributes:[NSDictionary dictionaryWithObject:l forKey:NSLinkAttributeName] range:NSMakeRange(0,[[as string]length])];
						[mas appendAttributedString:[[[NSAttributedString alloc]initWithString:@"\t"]autorelease]];
						if (![style nullStyle])
							[mas addAttributes:[style textAndStyleAttributes] range:NSMakeRange(0,[mas length])];
						[mas endEditing];
						NSString *endBit = [NSString stringWithFormat:@"%ld",[[layer page]pageNo]];
						NSMutableAttributedString *p = [[[NSMutableAttributedString alloc]initWithString:endBit]autorelease];
						l = [ACSDLink linkFrom:target to:self anchorID:anchor substitutePageNo:YES changeAttributes:NO];
						[p addAttributes:[NSDictionary dictionaryWithObject:l forKey:NSLinkAttributeName] range:NSMakeRange(0,[[p string]length])];
						[tocString beginEditing];
						[tocString appendAttributedString:mas];
						[tocString appendAttributedString:p];
						[tocString appendAttributedString:[[[NSAttributedString alloc]initWithString:@"\n"]autorelease]];
						[tocString endEditing];
					   }
				   }
			   }
		   }
		index = longestRange.location + longestRange.length;
	   }
   }

-(void)invalidateGraphicSizeChanged:(BOOL)sizeChanged shapeChanged:(BOOL)shapeChanged redraw:(BOOL)redraw notify:(BOOL)notify
   {
	[super invalidateGraphicSizeChanged:sizeChanged shapeChanged:shapeChanged redraw:redraw notify:notify];
	if (nextText)
		[nextText invalidateGraphicSizeChanged:sizeChanged shapeChanged:shapeChanged redraw:redraw notify:notify];
   }

-(NSString*)anchorStringForIndex:(unsigned)i
   {
	return [NSString stringWithFormat:@"#a%lx-%d",(NSUInteger)self,i];
   }

-(void)setAnchor:obj forRange:(NSRange)range
   {
	[[[self layoutManager] textStorage] beginEditing];
	[[[self layoutManager] textStorage] addAttributes:[NSDictionary dictionaryWithObject:obj forKey:ACSDAnchorAttributeName] range:range];
	[[[self layoutManager] textStorage] endEditing];	
   }

-(int)assignAnchorForRange:(NSRange)charRange
   {
	NSUInteger index = charRange.location;
	while (index < charRange.location + charRange.length)
	   {
		NSRange resultRange;
		if (id anc = [[[self layoutManager] textStorage]attribute:ACSDAnchorAttributeName atIndex:index effectiveRange:&resultRange])
			return [anc intValue];
		index = resultRange.location + resultRange.length;
	   }
	int anchorID = [self nextAnchorID];
	[self setAnchor:[NSNumber numberWithInt:anchorID] forRange:charRange];
	return anchorID;
   }

-(int)maxAnchorID
   {
	if (previousText)
		return [(ACSDText*)[[self layoutManager] delegate]maxAnchorID];	
	return maxAnchorID;
   }

-(void)setMaxAnchorID:(int)anc
   {
	if (previousText)
		[(ACSDText*)[[self layoutManager] delegate]setMaxAnchorID:anc];
	maxAnchorID = anc;
   }

-(int)nextAnchorID
   {
	int res = [self maxAnchorID];
	[self setMaxAnchorID:res+1];
	return res;
   }

-(void)uSetLink:(id)l forRange:(NSRange)range
   {
//	[[[self undoManager] prepareWithInvocationTarget:self] uSetLink:link];
	[[[self layoutManager] textStorage] beginEditing];
	[[[self layoutManager] textStorage] addAttributes:[NSDictionary dictionaryWithObject:l forKey:NSLinkAttributeName] range:range];
	[[[self layoutManager] textStorage] endEditing];	
   }

-(id)linkForRange:(NSRange)charRange
   {
	NSUInteger index = charRange.location;
	while (index < charRange.location + charRange.length)
	   {
		NSRange resultRange;
		if (id lnk = [[[self layoutManager] textStorage]attribute:NSLinkAttributeName atIndex:index effectiveRange:&resultRange])
			return lnk;
		index = resultRange.location + resultRange.length;
	   }
	return nil;
   }

-(ACSDText*)acsdTextForRange:(NSRange)charRange overflow:(BOOL*)ov
   {
	if (!previousText && !nextText)
		return self;
	NSRange characterRange = [self characterRange];
	NSInteger i = (int)charRange.location - characterRange.location;
	if (i >= 0 && i < (int)characterRange.length)
		return self;
	if (i < 0)
		return nil;
	if (nextText)
		return [(ACSDText*)nextText acsdTextForRange:charRange overflow:ov];
	*ov = YES;
	return self;
   }

-(id)checkLink:(ACSDLink*)l overflow:(BOOL*)ov
   {
	if (!previousText && !nextText)
		return self;
	int anchorID;
	if ((anchorID = [l anchorID]) < 0)
		return self;
	NSRange charRange = [self characterRange];
	NSUInteger index = charRange.location;
	while (index < charRange.location + charRange.length)
	   {
		NSRange ler;
		id anch = [[[self layoutManager] textStorage]attribute:ACSDAnchorAttributeName atIndex:index longestEffectiveRange:&ler inRange:charRange];
		if (anch && ([anch intValue] == anchorID))
			return self;
		index = ler.location + ler.length;
	   }
	charRange.location = 0;
	charRange.length = [[[self layoutManager] textStorage]length];
	index = charRange.location;
	while (index < charRange.location + charRange.length)
	   {
		NSRange ler;
		id anch = [[[self layoutManager] textStorage]attribute:ACSDAnchorAttributeName atIndex:index longestEffectiveRange:&ler inRange:charRange];
		if (anch && ([anch intValue] == anchorID))
			return [(ACSDText*)[[self layoutManager] delegate] acsdTextForRange:ler overflow:ov];
		index = ler.location + ler.length;
	   }
	return nil;
   }

-(BOOL)writeImageFromAttachment:(NSImage*)image options:(NSMutableDictionary*)options string:(NSMutableString*)currentString
   {
	NSString *imageSuffix,*imageType;
	imageSuffix = [[options objectForKey:@"htmlSettings"]objectForKey:@"imageSuffix"];
	imageType = [[options objectForKey:@"htmlSettings"]objectForKey:@"imageType"];
	NSData *imData = [image TIFFRepresentation];
	CGImageSourceRef cgImageSource = CGImageSourceCreateWithData((CFDataRef)imData,NULL);
	CGImageRef cgImageref = CGImageSourceCreateImageAtIndex(cgImageSource,0,NULL);
	CFRelease(cgImageSource);
	NSString *fileName = [imageNameForOptions(options) stringByAppendingPathExtension:imageSuffix];
	NSString *pathName = [options objectForKey:@"smallimages"];
	NSError *err;
	if (![[NSFileManager defaultManager]fileExistsAtPath:pathName])
		if (![[NSFileManager defaultManager] createDirectoryAtPath:pathName withIntermediateDirectories:NO attributes:nil error:&err])
		{
			CGImageRelease(cgImageref);
			return show_error_alert([NSString stringWithFormat:@"Error creating directory: %@ - %@",pathName,[err localizedDescription]]);
		}
	pathName = [pathName stringByAppendingPathComponent:fileName];
	NSURL *url = [NSURL fileURLWithPath:pathName];
	CGImageDestinationRef cgImageDest = CGImageDestinationCreateWithURL((CFURLRef)url,(CFStringRef)imageType,1,NULL);
	if (!cgImageDest)
		return show_error_alert([NSString stringWithFormat:@"Error creating image destination: %@",[url description]]);
	CGImageDestinationAddImage(cgImageDest,cgImageref,NULL);
	CGImageDestinationFinalize(cgImageDest);
	CFRelease(cgImageDest);
	CGImageRelease(cgImageref);
	[currentString appendFormat:@"<img src=\"smallimages/%@\"/>",fileName];
	return YES;
   }

-(NSArray*)parasFromTextOptions:(NSMutableDictionary*)options fontDict:(NSMutableDictionary*)fontDict
{
	NSMutableArray *paras = [NSMutableArray arrayWithCapacity:20];
	NSMutableDictionary *currentPara = nil;
	NSMutableDictionary *currentSpan = nil;
	NSMutableString *currentString = nil;
	NSRange resultRange;
	NSString *chars = [[[self layoutManager] textStorage] string];
	NSRange charRange = [self characterRange];
	NSUInteger index = charRange.location;
	BOOL suppressFirstIndent = false,suppressSpaceBefore = false;
	if (index == 0)
		suppressSpaceBefore = true;
	else
	{
		NSRange chr = {index-1,1};
		NSString *chstr = [chars substringWithRange:chr];
		if (![chstr isEqualToString:@"\n"])
		{
			suppressFirstIndent = true;
			suppressSpaceBefore = true;
		}
	}
	NSString *url = NULL;
	while (index < charRange.location + charRange.length)
	{
		NSDictionary *attrs = [[[self layoutManager] textStorage] attributesAtIndex:index longestEffectiveRange:&resultRange inRange:charRange];
		id lnk = [attrs objectForKey:NSLinkAttributeName];
		id anchor = [attrs objectForKey:ACSDAnchorAttributeName];
		id attachment = [attrs objectForKey:NSAttachmentAttributeName];
		NSString *anchorString = nil;
		if (anchor)
			anchorString = [self anchorStringForIndex:[anchor intValue]];
		url = [self link:lnk urlStringOptions:options];
		NSFont *font = [attrs objectForKey:NSFontAttributeName];
		NSFontSymbolicTraits symbolicTraits = [[font fontDescriptor]symbolicTraits];
		NSColor *col = [attrs objectForKey:NSForegroundColorAttributeName];
		NSParagraphStyle *para = [attrs objectForKey:NSParagraphStyleAttributeName];
		ACSDStyle *style = [attrs objectForKey:@"StyleAttribute"];
		int ul  = [[attrs objectForKey:NSUnderlineStyleAttributeName]intValue];
		TextStyleHolder *tsh = [TextStyleHolder textStyleHolderWithFont:font colour:col paragraph:para underline:ul 
															 lineHeight:[[self layoutManager]defaultLineHeightForFont:font]];
		if (style)
			tsh.generateAppleHelp = style.generateAppleHelp;
		NSNumber *fno;
		if ((fno = [fontDict objectForKey:tsh]) == nil)
		{
			fno = [options objectForKey:@"fontNo"];
			[fontDict setObject:fno forKey:tsh];
			[options setObject:[NSNumber numberWithInt:[fno intValue]+1] forKey:@"fontNo"];
		}
		if (currentPara == nil)
		{
			currentPara = [NSMutableDictionary dictionaryWithCapacity:3];
			[currentPara setObject:tsh forKey:@"style"];
			[currentPara setObject:[NSMutableArray arrayWithCapacity:10] forKey:@"spans"];
			[paras addObject:currentPara];
			if (suppressFirstIndent)
				[currentPara setObject:[NSNumber numberWithBool:suppressFirstIndent] forKey:@"suppressFirstIndent"];
			if (suppressSpaceBefore)
				[currentPara setObject:[NSNumber numberWithBool:suppressSpaceBefore] forKey:@"suppressSpaceBefore"];
		}
		currentSpan = [NSMutableDictionary dictionaryWithCapacity:10];
		[[currentPara objectForKey:@"spans"]addObject:currentSpan];
		currentString = [NSMutableString stringWithCapacity:30];
		[currentSpan setObject:tsh forKey:@"style"];		
		[currentSpan setObject:currentString forKey:@"string"];
		if (symbolicTraits & NSFontItalicTrait)
			[currentSpan setObject:[NSNumber numberWithBool:YES]forKey:@"italic"];
		if (symbolicTraits & NSFontBoldTrait)
			[currentSpan setObject:[NSNumber numberWithBool:YES]forKey:@"bold"];
		if (url || anchorString)
		{
			[currentString appendString:@"<a "];
			if (url)
				[currentString appendFormat:@"href=\"%@\"",url];
			if (anchorString)
				[currentString appendFormat:@" name=\"%@\"",anchorString];
			[currentString appendFormat:@">"];
		}
		if (attachment)
		{
			[self writeImageFromAttachment:[(NSCell*)[attachment attachmentCell]image]options:options string:currentString];
			int i = [[options objectForKey:@"imageNo"]intValue];
			[options setObject:[NSNumber numberWithInt:i+1] forKey:@"imageNo"];
		}
		BOOL eol = NO;
		while (index < resultRange.location + resultRange.length && !eol)
		{
			NSRange chr = {index,1};
			NSString *chstr = [chars substringWithRange:chr];
			if ([chstr isEqualToString:@"\n"])
			{
				eol = YES;
				currentPara = nil;
				suppressFirstIndent = false;
				suppressSpaceBefore = false;
			}
			else
			{
				if ([chstr isEqualToString:@"<"])
					[currentString appendString:@"&lt;"];
				else if ([chstr isEqualToString:@">"])
					[currentString appendString:@"&gt;"];
				else if ([chstr isEqualToString:@"&"])
					[currentString appendString:@"&amp;"];
				else
					[currentString appendString:chstr];
			}
			index++;
		}
		if (url || anchorString)
		{
			[currentString appendString:@"</a>"];
			url = nil;
		}
	}
	for (unsigned i = 0;i < [paras count];i++)
	{
		currentPara = [paras objectAtIndex:i];
		NSMutableArray *spans = [currentPara objectForKey:@"spans"];
		unsigned j = 0;
		while (j < [spans count])
		{
			NSDictionary *currentSpan = [spans objectAtIndex:j];
			NSString *str = [currentSpan objectForKey:@"string"];
			if ([str length] == 0)
				[spans removeObjectAtIndex:j];
			else
				j++;
		}
	}
	return paras;
}

-(void)convertTextToHTMLCSS:(NSMutableString*)cssString body:(NSMutableString*)bodyString fontDict:(NSMutableDictionary*)fontDict options:(NSMutableDictionary*)options
{
	NSArray *paras = [self parasFromTextOptions:options fontDict:fontDict];
	for (unsigned i = 0;i < [paras count];i++)
	{
		NSDictionary *currentPara = [paras objectAtIndex:i];
		TextStyleHolder *tsh = [currentPara objectForKey:@"style"];
		NSArray *spans = [currentPara objectForKey:@"spans"];
		if (tsh && tsh.generateAppleHelp && [spans count] > 0)
		{
			int segNo = [[options objectForKey:@"segno"]intValue];
			[bodyString appendFormat:@"\t\t\t<!-- AppleSegStart=\"S%d\" -->\n",segNo];
			[bodyString appendFormat:@"\t\t\t<A NAME=\"S%d\"></A>\n",segNo];
			[options setObject:[NSNumber numberWithInt:segNo+1] forKey:@"segNo"];
			NSDictionary *sp = [spans objectAtIndex:0];
			NSString *str = [sp objectForKey:@"string"];
			[bodyString appendFormat:@"\t\t\t<!-- AppleSegDescription=\"%@\" -->\n",str];
		}
		[bodyString appendFormat:@"\t\t\t<p class=p%d",[[fontDict objectForKey:tsh]intValue]];
		bool suppressFirstIndent = [currentPara objectForKey:@"suppressFirstIndent"];
		bool suppressSpaceBefore = [currentPara objectForKey:@"suppressSpaceBefore"];
		if (suppressSpaceBefore)
		{
			[bodyString appendString:@" style='padding-top:0px;"];
			if (suppressFirstIndent)
				[bodyString appendString:@"text-indent:0px;"];
			[bodyString appendString:@"'"];
		}
		[bodyString appendString:@">"];
		if ([spans count] == 0)
			[bodyString appendString:@"&nbsp;"];
		for (unsigned j = 0;j < [spans count];j++)
		{
			NSDictionary *currentSpan = [spans objectAtIndex:j];
			TextStyleHolder *spanTsh = [currentSpan objectForKey:@"style"];
			NSString *str = [currentSpan objectForKey:@"string"];
			if ((![spanTsh isEqual:tsh]) && ([str length] > 0))
				[bodyString appendFormat:@"<span class=\"p%d\">",[[fontDict objectForKey:spanTsh]intValue]];
			id bold,italic;
			if ((bold = [currentSpan objectForKey:@"bold"]))
				[bodyString appendString:@"<b>"];
			if ((italic = [currentSpan objectForKey:@"italic"]))
				[bodyString appendString:@"<i>"];
			[bodyString appendString:str];
			if (italic)
				[bodyString appendString:@"</i>"];
			if (bold)
				[bodyString appendString:@"</b>"];
			if ((![spanTsh isEqual:tsh]) && ([str length] > 0))
				[bodyString appendString:@"</span>"];				
		}
		[bodyString appendString:@"</p>\n"];
		if (tsh && tsh.generateAppleHelp && [spans count] > 0)
		{
			[bodyString appendString:@"\t\t\t<!-- AppleSegEnd -->\n"];
		}
	}
}

-(BOOL)htmlMustBeDoneAsImage
{
	return (transform != nil || alpha < 1.0 || (shadowType != nil && [shadowType colour]) || cornerRadius != 0.0);
}

-(void)processHTMLOptions:(NSMutableDictionary*)options
{
	if ([self htmlMustBeDoneAsImage])
	{
		[super processHTMLOptions:options];
		return;
	}
	NSMutableString *cssString = [options objectForKey:@"cssString"];
	NSMutableString *bodyString = [options objectForKey:@"bodyString"];
	NSMutableDictionary *fontDict = [options objectForKey:@"fontDict"];
	NSSize sz = [[[layer page] document]documentSize];
	NSRect b = [self bounds];
	NSString *objName = imageNameForOptions(options);
	float lpad = [textContainer lineFragmentPadding],rpad=lpad,tpad=topMargin,bpad=bottomMargin,strokeWidth=0.0,halfStrokeWidth=0.0;
	if (stroke && [stroke colour])
		halfStrokeWidth = (strokeWidth = [stroke lineWidth])/2;
	NSSize textsize = [self sizeOfLaidOutText];
	if (verticalAlignment == VERTICAL_ALIGNMENT_CENTRE)
	{
		float temp = b.size.height - (textsize.height + (tpad + bpad));
		if (temp > 0.0)
			tpad = temp / 2.0;
	}
	[cssString appendFormat:@"\t\t\t#%@ {position: absolute; top: %1.1fpx; left: %1.1fpx; height: %1.1fpx; width: %1.1fpx; padding-top: %1.1fpx;padding-left: %1.1fpx;padding-bottom: %1.1fpx;padding-right: %1.1fpx; margin: 0px; z-index: 1; ",
	 objName,sz.height-NSMaxY(b)+halfStrokeWidth,NSMinX(b)+halfStrokeWidth,b.size.height-(strokeWidth+tpad+bpad),b.size.width-(strokeWidth+lpad+rpad),tpad,lpad,bpad,rpad];
	if (stroke && [stroke colour])
		[cssString appendFormat:@"border: %1.1fpx solid %@;",[stroke lineWidth],string_from_nscolor([stroke colour])];
	if (fill && [fill colour])
		[cssString appendFormat:@"background-color: %@;",string_from_nscolor([fill colour])];
	[cssString appendString:@"}\n"];
	[bodyString appendFormat:@"\t\t<div id=\"%@\"",objName];
	[self processHTMLTriggers:bodyString];
	[bodyString appendString:@">\n\t\t\t"];
	[self convertTextToHTMLCSS:cssString body:bodyString fontDict:fontDict options:options];
	[bodyString appendFormat:@"\t\t</div>\n"];
	if (link)
		if ([link isKindOfClass:[NSURL class]])
		{
			[cssString appendFormat:@"\t\t\t#%@a {position: absolute; top: %1.1fpx; left: %1.1fpx; height: %1.1fpx; width: %1.1fpx; padding: 0px; margin: 0px; z-index: 1}\n",
			 objName,sz.height-NSMaxY(b)+halfStrokeWidth,NSMinX(b)+halfStrokeWidth,b.size.height-strokeWidth,b.size.width-strokeWidth];
			[bodyString appendFormat:@"<a href=\"%@\"><div id=\"%@a\">\n</div></a>",[link description],objName];
		}
	int i = [[options objectForKey:@"imageNo"]intValue];
	[options setObject:[NSNumber numberWithInt:i+1] forKey:@"imageNo"];
}

extern	NSMutableSet *checkSet;


-(void)addLinksForPDFContext:(CGContextRef) context
   {
	[super addLinksForPDFContext:context];
	NSRange charRange = [self characterRange];
	NSUInteger index = charRange.location;
	while (index < charRange.location + charRange.length)
	   {
		NSRange resultRange;
		id attr = [[[self layoutManager] textStorage] attribute:ACSDAnchorAttributeName atIndex:index longestEffectiveRange:&resultRange inRange:charRange];
		if (attr)
		   {
			int anchorID = [attr intValue];
			NSRange glyphRange = [[self layoutManager] glyphRangeForCharacterRange:NSMakeRange(index,1) actualCharacterRange:nil];
			NSRect b = [[self layoutManager] boundingRectForGlyphRange:glyphRange inTextContainer:textContainer];
			b = [self textContainerToRealCoords:b];
			if (!NSEqualRects(b,NSZeroRect))
			   {
				NSString *aname = [ACSDLink anchorNameForObject:self anchorID:anchorID];
				if ([checkSet containsObject:aname])
					NSLog(@"******anchor already used***********");
				else
					[checkSet addObject:aname];
				CGPDFContextAddDestinationAtPoint(context,(CFStringRef)aname,CGPointMake(NSMidX(b),NSMidY(b)));
				NSLog(@"anchor %d %@ - %@",anchorID,[[[[self layoutManager] textStorage]string]substringWithRange:resultRange],[ACSDLink anchorNameForObject:self anchorID:anchorID]);
			   }
		   }
		index = NSMaxRange(resultRange);
	   }
	index = charRange.location;
	while (index < charRange.location + charRange.length)
	   {
		NSRange resultRange;
		id lnk = [[[self layoutManager] textStorage] attribute:NSLinkAttributeName atIndex:index longestEffectiveRange:&resultRange inRange:charRange];
		if (lnk)
		   {
			NSUInteger count,i;
			NSRectArray rArray = [[self layoutManager] rectArrayForCharacterRange:resultRange withinSelectedCharacterRange:resultRange inTextContainer:textContainer rectCount:&count];
			NSRect r;
			if ([lnk isKindOfClass:[NSURL class]])
				for (i = 0;i < count;i++)
				   {
					r = [self textContainerToRealCoords:rArray[i]];
					CGPDFContextSetURLForRect(context,(CFURLRef)lnk,CGRectFromNSRect(r));
				   }
			else if ([lnk isKindOfClass:[ACSDLink class]])
			   {
				[lnk checkToObj];		
				for (i = 0;i < count;i++)
				   {
					r = [self textContainerToRealCoords:rArray[i]];
					CGPDFContextSetDestinationForRect(context,(CFStringRef)[lnk anchorNameForToObject],CGRectFromNSRect(r));
					NSLog(@"link %@ - %@",[[[[self layoutManager] textStorage]string]substringWithRange:resultRange],[lnk anchorNameForToObject]);
				   }
			   }
		   }
		index = NSMaxRange(resultRange);
	   }
   }

-(void)addTextLinksForPDFContext:(CGContextRef) context
   {
	NSRange charRange = [self characterRange];
	NSUInteger index = charRange.location;
	while (index < charRange.location + charRange.length)
	   {
		NSRange resultRange;
		id lnk = [[[self layoutManager] textStorage] attribute:NSLinkAttributeName atIndex:index longestEffectiveRange:&resultRange inRange:charRange];
		if (lnk)
		   {
			NSUInteger count,i;
			NSRectArray rArray = [[self layoutManager] rectArrayForCharacterRange:resultRange withinSelectedCharacterRange:resultRange inTextContainer:textContainer rectCount:&count];
			NSRect r;
			for (i = 0;i < count;i++)
			   {
				r = [self textContainerToRealCoords:rArray[i]];
				if ([[ACSDPrefsController sharedACSDPrefsController:nil]pdfLinkMode] != PDF_LINK_NONE)
				   {
					[[[ACSDPrefsController sharedACSDPrefsController:nil]pdfLinkHighlightColour]set];
					if ([[ACSDPrefsController sharedACSDPrefsController:nil]pdfLinkMode] == PDF_LINK_STROKE)
					   {
						[NSBezierPath setDefaultLineWidth:[[ACSDPrefsController sharedACSDPrefsController:nil]pdfLinkStrokeSize]];
						[NSBezierPath strokeRect:r];
					   }
					else
						NSRectFill(r);
				   }
			   }
		   }
		index = NSMaxRange(resultRange);
	   }
   }

-(ACSDPath*)wholeOutline
   {
	if (fill)
		return [self wholeFilledRect];
	return [super wholeOutline];
   }

-(void)invalidateTextFlower
   {
	if ([self doesTextFlow])
	   {
		[self setObjectsInFrontValid:NO];
		[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:YES notify:NO];
		[[self layoutManager]textContainerChangedGeometry:[self textContainer]];
	   }
   }

-(int)compareBoundsudlr:(ACSDText*)text
   {
    NSRect myB = [self transformedBounds];
	NSRect hisB = [text transformedBounds];
	float myY = NSMaxY(myB);
	float hisY = NSMaxY(hisB);
//	NSPoint myPoint = [self transformedBounds].origin;
//	NSPoint hisPoint = [text transformedBounds].origin;
	if (myY > hisY)
		return NSOrderedAscending;
	if (myY < hisY)
		return NSOrderedDescending;
	float myX = myB.origin.x;
	float hisX = hisB.origin.x;
	if (myX < hisX)
		return NSOrderedAscending;
	if (myX > hisX)
		return NSOrderedDescending;
	return NSOrderedSame;
   }



@end
