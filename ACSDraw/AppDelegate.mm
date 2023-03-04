#import "AppDelegate.h"
#import "ToolWindowController.h"
#import "StyleWindowController.h"
#import "ACSDImageRep.h"
#import "PalletteViewController.h"
#import "ACSDDocumentController.h"

ACSDDocumentController *docController;

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
		appKey = [NSDate date];
		[ACSDImageRep class];
        docController = [[ACSDDocumentController alloc]init];
        self.copiedScreens = [NSMutableArray arrayWithCapacity:5];
    }
	return self;
}

-(void)dealloc
{
    self.copiedScreens = nil;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    [[NSColorPanel sharedColorPanel]setShowsAlpha:YES];
    inspectorVisible = NO;
    NSMenu *m = [NSTextView defaultMenu];
    if (m)
    {
        while ([textMenu numberOfItems] > 0)
        {
            NSMenuItem *mi = (NSMenuItem*)[textMenu itemAtIndex:0];
            [textMenu removeItem:mi];
            [m addItem:mi];
        }
    }
    [[PalletteViewController sharedPalletteViewController]createPanels];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self afterLaunch];
    });
}

-(void)afterLaunch
{
    toolsVisible = YES;
    NSWindow *toolWindow = [[ToolWindowController sharedToolWindowController:nil]window];
    NSWindowOcclusionState occ = toolWindow.occlusionState;
    if (!(occ & NSWindowOcclusionStateVisible))
        //[toolWindow makeKeyAndOrderFront:nil];
    //[toolWindow setIsVisible:YES];
        [[ToolWindowController sharedToolWindowController:nil]showWindow:self];
    [[PalletteViewController sharedPalletteViewController]showAllPallettes];
}


- (IBAction)showPanel:(id)sender
{
	[[PalletteViewController sharedPalletteViewController]activatePanel:(int)[sender tag]];
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
    if (toolsVisible)
    {
        [[[ToolWindowController sharedToolWindowController:nil]window]orderOut:self];
        [[PalletteViewController sharedPalletteViewController]hideAllPallettes];
    }
    else
    {
        [[ToolWindowController sharedToolWindowController:nil]showWindow:nil];
        [[PalletteViewController sharedPalletteViewController]showAllPallettes];
    }
    toolsVisible = !toolsVisible;

}


@end
