/* PagesPanelController */

#import <Cocoa/Cocoa.h>
#import "PanelController.h"
#import "TableViewDelegate.h"

extern NSString *ACSDrawLayerPasteboardType;
extern NSString *ACSDrawLayerIntPasteboardType;
extern NSString *ACSDrawLayerSelPasteboardType;
extern NSString *ACSDrawPageIntPasteboardType;

@interface PagesPanelController : PanelController<TableViewDelegate>
{
    IBOutlet id layerMinus;
    IBOutlet id layerPlus;
    IBOutlet id layerTableView;
    IBOutlet id pageMinus;
    IBOutlet id pagePlus;
    IBOutlet id pageTableView;
    IBOutlet id masterListTableView;
    IBOutlet id masterTypeRB;
    IBOutlet id pageType;
    IBOutlet id useMasterRB;
    IBOutlet id useMasterTitle;
    IBOutlet id pageTitle;
    IBOutlet id backgroundColour;
    IBOutlet id inactiveCB;
	NSMutableArray *layerList;
	NSMutableArray *pageList;
}

- (IBAction)masterCBHit:(id)sender;
- (IBAction)masterTypeRBHit:(id)sender;
- (IBAction)useMasterRBHit:(id)sender;
- (IBAction)layerMinusHit:(id)sender;
- (IBAction)layerPlusHit:(id)sender;
- (IBAction)pageMinusHit:(id)sender;
- (IBAction)pagePlusHit:(id)sender;
- (IBAction)pageTitleHit:(id)sender;
- (IBAction)inactiveCBHit:(id)sender;
- (IBAction)backgroundColourHit:(id)sender;
- (void)setLayerList:(NSMutableArray*)f;
- (void)setControlsForLayers:(NSInteger)layerInd;
- (void)pageChanged:(NSNotification *)notification;
- (void)setPageList:(NSMutableArray*)f;
-(void)setControls;
- (void)zeroControls;
-(void)selectLayerRowWithNoActions:(int)row;
-(void)selectPageRowWithNoActions:(int)row;
- (void)setControlsForPage;

@end
