//
//  ACSDText.h
//  ACSDraw
//
//  Created by Alan Smith on Thu Jan 31 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "ACSDGraphic.h"
#import "TextCharacteristics.h"

extern NSString *ACSDAnchorAttributeName;
extern NSString *ACSDrawTextPBoardType;

enum
   {
	FLOW_METHOD_NONE,
	FLOW_METHOD_NO_BESIDE,
	FLOW_METHOD_AROUND,
   };


@interface ACSDText : ACSDGraphic<NSLayoutManagerDelegate,NSTextViewDelegate,ACSDGraphicCornerRadius,TextCharacteristics>
   {
	float topMargin,leftMargin,bottomMargin,rightMargin;
	VerticalAlignment verticalAlignment;
	ACSDText *previousText,*nextText;
	NSLayoutManager *layoutManager;
	NSTextContainer *textContainer;
	int maxAnchorID;
	int flowMethod;
	float flowPad;
	NSMutableSet *objectsInTheWay,*objectsInFront;
	float cornerRadius,originalCornerRadius,originalCornerRatio;
	ACSDPath *pathInTheWay;
	BOOL objectsInFrontValid,objectsInTheWayValid,pathInTheWayValid,mayContainSubstitutions;
@private
    NSTextStorage *contents;
	BOOL overflow;
	BOOL possibleDeletedLinks,
		possibleMovedLinks;
   }

+ (ACSDText*)dupAndFlowText:(ACSDText*)graphic;
+(void)sortOutLinkedTextGraphics:(ACSDText*)startText;
- (void)setContents:(id)contents;
- (NSTextStorage *)contents;
- (float)flowPad;
- (void)setTopMargin:(float)m;
- (void)setLeftMargin:(float)m;
- (void)setBottomMargin:(float)m;
- (void)setRightMargin:(float)m;
- (void)setVerticalAlignment:(VerticalAlignment)al;
- (void)startEditingWithEvent:(NSEvent *)event inView:(GraphicView *)view;
- (void)endEditingInView:(GraphicView *)view;
- (BOOL)setGraphicLeftMargin:(float)m notify:(BOOL)notify;
- (BOOL)setGraphicRightMargin:(float)m notify:(BOOL)notify;
- (BOOL)setGraphicTopMargin:(float)m notify:(BOOL)notify;
- (BOOL)setGraphicBottomMargin:(float)m notify:(BOOL)notify;
- (void)setGraphicVerticalAlignment:(VerticalAlignment)a notify:(BOOL)notify;
- (BOOL)setGraphicFlowPad:(float)m notify:(BOOL)notify;
- (NSSize)sizeOfLaidOutText;
- (NSRect)boundsWithinMargins;
- (int)flowMethod;
- (void)setFlowMethod:(int)al;
-(ACSDPath*)pathInTheWay;
-(NSSet*)objectsInTheWay;

- (id)initWithName:(NSString*)n fill:(ACSDFill*)f stroke:(ACSDStroke*)str rect:(NSRect)r layer:(ACSDLayer*)l
			xScale:(float)xs yScale:(float)ys rotation:(float)rot shadowType:(ShadowType*)st label:(ACSDLabel*)lab alpha:(float)a contents:(NSTextStorage*)cont
		 topMargin:(float)tm leftMargin:(float)lm bottomMargin:(float)bm rightMargin:(float)rm verticalAlignment:(VerticalAlignment)vA;

-(ACSDText*)previousText;
-(ACSDText*)nextText;
-(void)setNextText:(ACSDText*)nt;
- (void)unlinkFromText;
- (void)linkToText:(ACSDText*)previousText;
-(NSLayoutManager*)layoutManager;
-(NSTextContainer*)textContainer;
-(void)allocateTextSystemStuff;
-(NSRange)characterRangeUnderPoint:(NSPoint)pt;
-(void)setAnchor:obj forRange:(NSRange)range;
-(void)uSetLink:(id)l forRange:(NSRange)range;
-(id)linkForRange:(NSRange)charRange;
-(void)drawHighlightRect:(NSRect)r colour:(NSColor*)col charRange:(NSRange)charRange;
-(void)drawHighlightRect:(NSRect)r colour:(NSColor*)col anchorID:(int)anchorID overflow:(BOOL)ov;
-(int)nextAnchorID;
-(int)maxAnchorID;
-(void)setMaxAnchorID:(int)anc;
-(int)assignAnchorForRange:(NSRange)charRange;
-(void)addTextLinksForPDFContext:(CGContextRef) context;
- (void)setGraphicFlowMethod:(int)a notify:(BOOL)notify;
-(void)setObjectsInFrontValid:(BOOL)b;
-(void)setObjectsInTheWayValid:(BOOL)b;
-(void)setPathInTheWayValid:(BOOL)b;
-(BOOL)objectsInFrontValid;
-(BOOL)objectsInTheWayValid;
-(BOOL)pathInTheWayValid;
-(void)updateRange:(NSRange)allRange forNewStyle:(ACSDStyle*)newStyle;
-(void)forceUpdateRange:(NSRange)allRange forStyle:(ACSDStyle*)style;
-(void)setMayContainSubstitutions:(BOOL)b;
-(NSRange)characterRange;
-(int)compareBoundsudlr:(ACSDText*)text;
-(void)addTOCStyles:(NSArray*)styles toString:(NSMutableAttributedString*)tocString mappedStyles:(NSArray*)mappedStyles target:(ACSDText*)target;
-(NSRange)removeTextLink:(ACSDLink*)lnk;
-(NSRange)rangeForAnchor:(int)anchorID;
- (BOOL)uUnlinkText;
- (BOOL)uLinkToText:(ACSDText*)sText;
-(BOOL)htmlMustBeDoneAsImage;

@end

