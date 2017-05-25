//
//  DocController.mm
//  ACSDraw
//
//  Created by alan on 08/02/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "DocController.h"
#import "GraphicView.h"
#import "ACSDGraphic.h"


@implementation DocController

-(id)init
{
	if (self = [super initWithTitle:@"Doc"])
	{
	}
	return self;
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
	[[additionalCSS textStorage]setAttributedString:[[NSAttributedString alloc]initWithString:ac]];
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
    NSColor *col = [[[self inspectingGraphicView]document]backgroundColour];
    if (col)
        [backgroundColour setColor:col];
}

- (void)documentChanged:(NSNotification *)notification
{
	[self setDocumentControls:[[self inspectingGraphicView]document]];
}

-(void)awakeFromNib
{
	[super awakeFromNib];
	rowForContextualMenu = -1;
	displayRowForContextualMenu = -1;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentChanged:) name:ACSDDocumentDidChangeNotification object:nil];
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
