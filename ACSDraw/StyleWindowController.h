/* StyleWindowController */

#import <Cocoa/Cocoa.h>

@class GraphicView;
@class ACSDStyle;
@class ACSDTableView;

@interface StyleWindowController : NSWindowController
   {
    IBOutlet id basedOnReset;
    IBOutlet id basedOnTableSource;
    IBOutlet id faceTableSource;
    IBOutlet id firstIndent;
    IBOutlet id fontFamilyTableSource;
    IBOutlet id fontSizeTableSource;
    IBOutlet id foregroundColourWell;
    IBOutlet id justifyMatrix;
    IBOutlet id leading;
    IBOutlet id leftIndent;
    IBOutlet id rightIndent;
    IBOutlet id sizeText;
    IBOutlet id spaceAfter;
    IBOutlet id spaceBefore;
    IBOutlet id styleTableSource;
	IBOutlet NSButton *genHelpCB;
    GraphicView *inspectingGraphicView;
	BOOL actionsDisabled;
   }

+ (id)sharedStyleWindowController;
- (void)textSelectionChanged:(NSNotification *)notification;
-(void)uInsertStyle:(ACSDStyle*)st atIndex:(NSInteger)row;
-(ACSDStyle*)currentStyle;
-(void)uSetStyle:(ACSDStyle*)st name:(NSString*)n;
-(void)uInsertStyle:(ACSDStyle*)st;
-(void)uUpdateStyleWithAttributes:(NSMutableDictionary*)attr;
- (IBAction)genHelpCBHit:(id)sender;

@end
