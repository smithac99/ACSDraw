/* ACSDPrefsController */

#import <Cocoa/Cocoa.h>

extern NSString *ACSDGuideColourDidChangeNotification;
extern NSString *ACSDSelectionColourDidChangeNotification;
extern NSString *ACSDHotSpotSizeDidChangeNotification;
extern NSString *ACSDSnapSizeDidChangeNotification;
extern NSString *ACSDBackgroundColourChange;
extern NSString *ACSDBackgroundTypeChange;
extern NSString *prefsRenameString;
extern NSString *prefsRenameStartFromString;
extern NSString *prefsRegexpPattern;
extern NSString *prefsRegexpTemplate;
extern NSString *prefsImageLibs;
extern NSString *prefsDocScale;
extern NSString *prefsDocSizeWidth;
extern NSString *prefsDocSizeHeight;
extern NSString *prefsDocSizeRow;
extern NSString *prefsDocSizeColumn;
extern NSString *prefSVGInlineEmbedded;
extern NSString *prefsBatchScalePage;
extern NSString *prefsBatchScaleLayer;
extern NSString *prefsBatchScaleObject;
extern NSString *prefsBatchScaleScale;

#define BACKGROUND_DRAW_NONE 0
#define BACKGROUND_DRAW_CHECKERS 1
#define BACKGROUND_DRAW_COLOUR 2

enum
   {
	PDF_LINK_NONE,
	PDF_LINK_STROKE = 1,
	PDF_LINK_COLOUR = 2,
    PDF_LINK_TEXT_COLOUR = 4,
    PDF_LINK_TEXT_BOLD = 8,
    PDF_LINK_TEXT_UNDERLINE = 16
   };

@interface ACSDPrefsController : NSWindowController<NSTableViewDataSource,NSTableViewDelegate>
{
    IBOutlet NSColorWell* guideColour;
    IBOutlet id hotSpotSize;
    IBOutlet NSColorWell* selectionColour;
    IBOutlet NSColorWell* hiliteColour;
    IBOutlet id snapSize;
    IBOutlet id pdfLinkHighlightingMatrix;
	IBOutlet id pdfLinkHighlightingStroke;
	IBOutlet NSColorWell* pdfLinkHighlightingColourWell;
    IBOutlet NSButton* openAfterExportCB;
	IBOutlet NSColorWell* backGroundColourWell;
	IBOutlet NSMatrix* backgroundColourTypeMatrix;
    __weak IBOutlet NSTableView *imageLibTableView;
}

@property (retain) IBOutlet NSView* exportAccessoryView;

+ (id)sharedACSDPrefsController:(ACSDPrefsController*)controller;
- (IBAction)guideColourHit:(id)sender;
- (IBAction)hotSpotSizeHit:(id)sender;
- (IBAction)selectionColourHit:(id)sender;
- (IBAction)snapSizehit:(id)sender;
- (NSColor*)selectionColour;
- (NSColor*)guideColour;
- (NSColor*)hiliteColour;
- (int)snapSize;
- (int)hotSpotSize;
- (NSColor*)pdfLinkHighlightColour;
- (int)pdfLinkMode;
- (float)pdfLinkStrokeSize;
-(NSView*)exportAccessoryView;
-(NSButton*)openAfterExportCB;
- (IBAction)openAfterExportCBHit:(id)sender;
-(int)backgroundType;
- (IBAction)backgroundColourTypeHit:(id)sender;
-(NSColor*)backgroundColour;
- (IBAction)backgroundColourHit:(id)sender;
-(BOOL)showPathDirection;
-(IBAction)toggleShowPathDirection:(id)sender;

@end
