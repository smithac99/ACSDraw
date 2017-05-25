/* ShadowPanelController */

#import <Cocoa/Cocoa.h>
#import "PanelController.h"

@interface ShadowPanelController : PanelController
{
    IBOutlet id radiusSlider;
    IBOutlet id shadowTableView;
    IBOutlet id shadowListTableSource;
    IBOutlet id shadowPlus;
    IBOutlet id shadowMinus;
    IBOutlet id shadowWell;
    IBOutlet id xOffsetSlider;
    IBOutlet id yOffsetSlider;
	NSMutableArray *shadowList;
}

+ (id)sharedShadowPanelController;
- (void)setShadowList:(NSMutableArray*)f;
- (IBAction)shadowPlusHit:(id)sender;
- (IBAction)shadowMinusHit:(id)sender;
- (IBAction)shadowWellHit:(id)sender;
- (IBAction)duplicateShadow:(id)sender;

-(void)refreshShadows;

@end
