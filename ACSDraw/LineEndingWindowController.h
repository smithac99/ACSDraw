/* LineEndingWindowController */

#import <Cocoa/Cocoa.h>
#import "GraphicView.h"
#import "ACSDLineEnding.h"
#import "LineEndPreview.h"
#import "SnapLine.h"
#import "GraphicRulerView.h"

@interface LineEndingWindowController : NSWindowController
   {
    IBOutlet GraphicView *graphicView;
	IBOutlet NSTextField *offsetText;
	IBOutlet NSSlider *offsetSlider;
	IBOutlet NSTextField *aspectText;
	IBOutlet NSSlider *aspectSlider;
	IBOutlet NSTextField *scaleText;
	IBOutlet NSSlider *scaleSlider;
	IBOutlet NSSlider *zoomSlider;
	IBOutlet LineEndPreview *lineEndPreview;
	IBOutlet id fillTypeRBMatrix;
	ACSDLineEnding *lineEnding,*temporaryLineEnding;
	NSMutableArray *pages;
	GraphicRulerView *horizontalRuler,*verticalRuler;
	SnapLine *verticalGuideLine,*horizontalGuideLine;
	NSUndoManager *undoManager;
   }

- (id)initWithLineEnding:(ACSDLineEnding*)le;
- (GraphicView*)graphicView;
- (NSUndoManager*)undoManager;
- (void)graphicsUpdated;
-(ACSDLineEnding*)tempLineEnding;
-(void)setTemporaryLineEnding:(ACSDLineEnding*)p;
-(ACSDLineEnding*)temporaryLineEnding;
-(id)representedObject;
- (NSSlider*)zoomSlider;
- (IBAction)zoomSliderHit:(id)sender;
-(BOOL)dirty;

@end
