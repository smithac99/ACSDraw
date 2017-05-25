/* DocPanelController */

#import <Cocoa/Cocoa.h>
#import "PanelController.h"

@interface DocPanelController : PanelController
{
    IBOutlet id docTitle;
    IBOutlet id documentHeight;
    IBOutlet id documentWidth;
    IBOutlet id viewMagnification;
    IBOutlet id scriptURL;
    IBOutlet id additionalCSS;
    IBOutlet id backgroundColour;
}

+ (id)sharedDocPanelController;

- (IBAction)backgroundColourHit:(id)sender;
- (IBAction)docTitleHit:(id)sender;
- (IBAction)scriptURLHit:(id)sender;
- (IBAction)documentWidthHit:(id)sender;
- (IBAction)documentHeightHit:(id)sender;
- (IBAction)viewMagnificationHit:(id)sender;
- (IBAction)additionalCSSHit:(id)sender;

@end
