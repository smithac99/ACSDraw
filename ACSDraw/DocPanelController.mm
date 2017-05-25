#import "DocPanelController.h"
#import "GraphicView.h"
#import "ACSDGraphic.h"
#import "ACSDRect.h"
#import "DragView.h"
#import "PanelCoordinator.h"

DocPanelController *_sharedDocPanelController = nil;

@implementation DocPanelController

+ (id)sharedDocPanelController
{
	if (!_sharedDocPanelController)
		[PanelCoordinator sharedPanelCoordinator];
    return _sharedDocPanelController;
}
- (void)zeroControls
{
	[documentWidth setEnabled:NO];
	[documentHeight setEnabled:NO];
	[viewMagnification setEnabled:NO];
	[docTitle setEnabled:NO];
	[scriptURL setEnabled:NO];
	[additionalCSS setEditable:NO];
}

-(void)setDocumentControls:(ACSDrawDocument*)doc
{
	[docTitle setEnabled:YES];
	[documentWidth setEnabled:YES];
	[documentHeight setEnabled:YES];
	[viewMagnification setEnabled:YES];
	[scriptURL setEnabled:YES];
	[additionalCSS setEditable:YES];
	[backgroundColour setEnabled:YES];
	NSString *ac = [[[self inspectingGraphicView] document]additionalCSS];
	if (ac == nil)
		ac = @"";
	[[additionalCSS textStorage]setAttributedString:[[[NSAttributedString alloc]initWithString:ac]autorelease]];
	NSSize sz = [[self inspectingGraphicView] bounds].size;
	[documentWidth setFloatValue:sz.width];
	[documentHeight setFloatValue:sz.height];
	NSString *t = [[[self inspectingGraphicView] document]docTitle];
	if (t == nil)
		t = @"";
	[docTitle setStringValue:t];
	t = [[[self inspectingGraphicView] document]scriptURL];
	if (t == nil)
		t = @"";
	[scriptURL setStringValue:t];
	[viewMagnification setFloatValue:[[self inspectingGraphicView] magnification]*100];
	[backgroundColour setColor:[[[self inspectingGraphicView]document]backgroundColour]];
}

-(void)awakeFromNib
{
	_sharedDocPanelController = self;
	[super awakeFromNib];
	rowForContextualMenu = -1;
	displayRowForContextualMenu = -1;
}

- (IBAction)backgroundColourHit:(id)sender
{
	[[[self inspectingGraphicView]document]uSetBackgroundColour:[sender color]];
	[[[self inspectingGraphicView] undoManager] setActionName:@"Set Background Colour"];	
}

- (IBAction)docTitleHit:(id)sender
{
	[[self inspectingGraphicView] changeDocTitle:[docTitle stringValue]];
}

- (IBAction)scriptURLHit:(id)sender
{
	[[self inspectingGraphicView] changeScriptURL:[scriptURL stringValue]];
}

- (IBAction)documentWidthHit:(id)sender
{
	[[self inspectingGraphicView] changeDocumentWidth:[documentWidth floatValue]];
}

- (IBAction)documentHeightHit:(id)sender
{
	[[self inspectingGraphicView] changeDocumentHeight:[documentHeight floatValue]];
}

- (IBAction)viewMagnificationHit:(id)sender
{
}

- (IBAction)additionalCSSHit:(id)sender
{
	[[self inspectingGraphicView]changeAdditionalCSS:[[additionalCSS textStorage]string]];
}

- (void)textDidChange:(NSNotification *)notif
{
	if (![self inspectingGraphicView])
		return;
	[self additionalCSSHit:self];
}

@end
