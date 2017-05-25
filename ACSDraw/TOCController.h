/* TOCController */

#import <Cocoa/Cocoa.h>

@class MainWindowController;

@interface TOCController : NSObject
   {
    IBOutlet id allToTOCButton;
    IBOutlet id TOCToAllButton;
    IBOutlet id mapMenu;
	MainWindowController *controller;
	NSMutableArray *keepStyles;	
   }

@property (retain) IBOutlet id tocSheet,allStyleSource,tocStyleSource;

- (id)initWithController:(MainWindowController*)cont;
- (IBAction)allToTOCButtonHit:(id)sender;
- (IBAction)TOCToAllButtonHit:(id)sender;
-(void)setStyles:(NSArray*)styles;
- (IBAction)mapMenuHitHit:(id)sender;
@end

