/* MainWindowController */

#import <Cocoa/Cocoa.h>
#import "GroupViewController.h"
NSImage *ImageFromFile(NSString* str);

@class TOCController;
@class GraphicView;
@class ACSDPathElement;
@class GroupViewController;

CGColorSpaceRef getRGBColorSpace();

@interface MainWindowController : NSWindowController
{
    IBOutlet GraphicView *graphicView;
	NSMutableArray *pages;
	BOOL printing;
	int viewNumber;
	IBOutlet NSTextField *scaleTextField;
	IBOutlet NSTextField *rotateTextField;
	IBOutlet NSTextField *linkTextField;
	IBOutlet NSTextField *docSizeHeight;
	IBOutlet NSTextField *docSizeWidth;
	IBOutlet NSMatrix *docSizeMatrix;
	TOCController *tocController;
	IBOutlet NSTextField *genTextField,*genTextTitle;
	IBOutlet NSTextField *renameTextField,*renameStartFromTextField;
	IBOutlet NSTextField *regexpPattern,*regexpTemplate,*regexpMsg;
    IBOutlet NSMatrix *renameOrderByMatrix;
    IBOutlet NSButton *renameRowDescendingCB,*renameColDescendingCB;
	
	IBOutlet NSTextField *epPtX,*epPtY,*epCP1X,*epCP1Y,*epCP2X,*epCP2Y;
	IBOutlet NSButton *epCBCP1,*epCBCP2;
    
    IBOutlet NSTextField *repeatwTextField,*repeathtextField,*repeatColsTextField,*repeatRowsTextField,*repeatxincTextField,*repeatyincTextField,*rowOffsetTextField;
    
}

@property (retain) IBOutlet NSPanel *scaleSheet,*rotateSheet,*abslinkSheet,*docSizeSheet,*genTextSheet,*renameSheet,*renameRegexpSheet,*repeatSheet,*editPointSheet;
@property (retain) IBOutlet GroupViewController *groupViewController;
@property (retain) IBOutlet NSWindow *groupWindow;

- (id)initWithPages:(NSMutableArray*)list;
- (GraphicView*)graphicView;
- (NSUndoManager*)undoManager;
- (void)adjustWindowSize;
-(CGImageRef)cgImageFromCurrentPageOfSize:(NSSize)sz;
-(CGImageRef)cgImageFromCurrentPageSelectionOnlyDrawSelectionOnly:(BOOL)drawSelectionOnly;
- (NSData*)tiffRepresentation;
- (NSData*)epsRepresentation;
- (NSData*)pdfRepresentation;
- (void)writePDFRepresentationToURL:(NSURL*)url;
-(int)importImage:(NSString*)str;
-(BOOL)printing;
- (void)showRotateDialog;
-(void)setViewNumber:(int)vn;
-(void)generateTocUsingStyles:(NSArray*)styles;
- (IBAction)closeScaleDocSheet: (id)sender;
//-(NSRect)rectCroppedToOpaqueSelectionOnly:(BOOL)selectionOnly;
-(NSRect)rectCroppedToOpaqueSelectionOnly:(BOOL)selectionOnly drawSelectionOnly:(BOOL)drawSelectionOnly;
NSBitmapImageRep *newBitmap(int width,int height);
- (IBAction)absoluteLink: (id)sender;
- (IBAction)closeSheet: (id)sender;
- (IBAction)selectLayerWithName:(id)sender;
-(void)showEditPointDialogForPathElement:(ACSDPathElement*)pe;

@end
