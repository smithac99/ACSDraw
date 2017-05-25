//
//  HTMLAccumulator.h
//  ACSDraw
//
//  Created by alan on 13/07/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class WebView;

@interface HTMLAccumulator : NSObject 
{
	NSMutableDictionary *htmlDict;
	IBOutlet	WebView *webView;
	NSArray *HTMLSearchStrings;
	NSMutableArray *queue;
	NSString *name;
	NSLock *cLock;
	unsigned queueIndex;
}

@property (retain)NSString *name;

-(BOOL)lookUpItem:(NSString*)nm;
+(id)sharedHTMLAccumulator;
-(void)exportSavedHTML:(NSString*)nm;
-(void)addToQueue:(NSString*)nm;
-(void)startQueue;

@end
