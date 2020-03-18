//
//  ContainerPalletteController.h
//  ACSDraw
//
//  Created by alan on 07/02/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class ViewController;
@class ContainerTabSubview;
@class ACSDFieldEditor;
@class SMTextView;

@interface ContainerPalletteController : NSObject 
{
	IBOutlet id pallette;
	IBOutlet id containerTabView;
	IBOutlet id containerContentView;
	NSMutableArray* viewControllers;
	NSMutableArray* tabSubviews;
	NSArray *topLevelObjects;
	int currentItem;
	int identifier;
}

@property (retain) ACSDFieldEditor *fieldEditor;
@property (retain) SMTextView *tableFieldEditor;

+(ContainerPalletteController*)palletteControllerWithIdentifier:(int)i;
-(id)initWithIdentifier:(int)i;
-(NSWindow*)window;
-(void)registerViewController:(ViewController*)vc;
-(void)tabHit:(ContainerTabSubview*)tsv;
-(void)removeTab:(ContainerTabSubview*)tsv;
-(int)identifier;
-(ContainerPalletteController*)detachTab:(ContainerTabSubview*)tsv;
-(NSArray*)tabSubviews;
@end
