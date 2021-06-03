/* PatternWindowController */

#import <Cocoa/Cocoa.h>

#import "GraphicView.h"
#import "ACSDPattern.h"
#import "PatternPreview.h"
#import "SnapLine.h"
#import "GraphicRulerView.h"

@interface PatternWindowController : NSWindowController
{
    IBOutlet id spacingText;
    IBOutlet id spacingSlider;
    IBOutlet id offsetTypeRBMatrix;
    IBOutlet id patternModeRBMatrix;
    IBOutlet id graphicView;
    IBOutlet id patternPreview;
    IBOutlet id offsetText;
    IBOutlet id offsetSlider;
    IBOutlet id opacityText;
    IBOutlet id opacitySlider;
    IBOutlet id scaleText;
    IBOutlet id scaleSlider;
    IBOutlet id backgroundColourWell;
    IBOutlet NSTextField *originXText;
    IBOutlet NSTextField *originYText;
    __weak IBOutlet NSPopUpButton *layoutPopUp;
    ACSDPattern *pattern;
	NSMutableArray *pages;
	GraphicRulerView *horizontalRuler,*verticalRuler;
	SnapLine *verticalOriginLine,*horizontalOriginLine,*verticalLimitLine,*horizontalLimitLine;
	BOOL actionsDisabled;
	NSUndoManager *undoManager;
	ACSDPattern* temporaryPattern;
}

@property (nonatomic) BOOL displayClip;
@property (nonatomic) float displayRotation;

- (id)initWithPattern:(ACSDPattern*)p;
- (GraphicView*)graphicView;
- (NSUndoManager*)undoManager;
- (void)graphicsUpdated;
-(ACSDPattern*)tempPattern;
-(void)setTemporaryPattern:(ACSDPattern*)p;
-(ACSDPattern*)temporaryPattern;

- (void)setActionsDisabled:(BOOL)disabled;
- (BOOL)actionsDisabled;
-(id)representedObject;
-(ACSDPattern*)updatedTemporaryPattern;
-(void)otherDrawing:(NSRect)r;
-(BOOL)dirty;
-(IBAction)backgroundColourWellHit:(id)sender;


@end
