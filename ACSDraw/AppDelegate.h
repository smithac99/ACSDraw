/* AppDelegate */

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject
   {
	NSCalendarDate *appKey;
    IBOutlet id textMenu;
	BOOL toolsVisible,inspectorVisible;
   }

@property (retain) NSMutableArray *copiedScreens;

- (IBAction)showToolPaletteAction:(id)sender;
- (IBAction)showStylesPanelAction:(id)sender;
- (void)hideShowPallettes;


@end

BOOL show_error_alert(NSString *msg1);
