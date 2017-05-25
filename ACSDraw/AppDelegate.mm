#import "AppDelegate.h"
#import "ToolWindowController.h"
#import "StyleWindowController.h"
#import "ACSDImageRep.h"
#import "PalletteViewController.h"

BOOL show_error_alert(NSString *msg1)
{
	NSRunAlertPanel(@"Error",@"%@",@"OK",nil,nil,msg1);
	return NO;
}

@implementation AppDelegate

- (id) init
{
	if (self = [super init])
    {
		appKey = [[NSCalendarDate calendarDate]retain];
		[ACSDImageRep class];
        self.copiedScreens = [NSMutableArray arrayWithCapacity:5];
    }
	return self;
}

-(void)dealloc
{
	if (appKey)
		[appKey release];
    self.copiedScreens = nil;
	[super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
   {
	[[NSColorPanel sharedColorPanel]setShowsAlpha:YES];
	toolsVisible = [[[ToolWindowController sharedToolWindowController:nil]window]isVisible];
	inspectorVisible = NO;
	NSMenu *m = [NSTextView defaultMenu];
	if (m)
	   {
		while ([textMenu numberOfItems] > 0)
		   {
			NSMenuItem *mi = (NSMenuItem*)[[textMenu itemAtIndex:0]retain];
			[textMenu removeItem:mi];
			[m addItem:mi];
			[mi release];
		   }
	   }
	[[PalletteViewController sharedPalletteViewController]createPanels];
   }

- (IBAction)showPanel:(id)sender
{
	[[PalletteViewController sharedPalletteViewController]showPanel:(int)[sender tag]];
}

- (IBAction)showStylesPanelAction:(id)sender
{
    [[StyleWindowController sharedStyleWindowController] showWindow:sender];
}

- (IBAction)showToolPaletteAction:(id)sender
   {
    [[ToolWindowController sharedToolWindowController:nil] showWindow:sender];
   }

- (void)hideShowPallettes
   {
	if ([[[ToolWindowController sharedToolWindowController:nil]window]isVisible])
	   {
		toolsVisible = [[[ToolWindowController sharedToolWindowController:nil]window]isVisible];
		[[[ToolWindowController sharedToolWindowController:nil]window]orderOut:self];
	   }
	else
	   {
		if (toolsVisible)
			[[ToolWindowController sharedToolWindowController:nil]showWindow:self];
	   }
   }


@end
