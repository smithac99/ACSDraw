/* AppDelegate */

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject
   {
	NSDate *appKey;
	BOOL toolsVisible,inspectorVisible;
   }

@property (retain) NSMutableArray *copiedScreens;
@property IBOutlet NSMenu *textMenu;

- (IBAction)showToolPaletteAction:(id)sender;
- (IBAction)showStylesPanelAction:(id)sender;
- (void)hideShowPallettes;


@end

BOOL show_error_alert(NSString *msg1);
