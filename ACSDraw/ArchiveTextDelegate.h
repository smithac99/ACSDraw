//
//  ArchiveTextDelegate.h
//  ACSDraw
//
//  Created by alan on 07/02/07.
//  Copyright 2007 Alan C Smith. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ArchiveDelegate.h"

@class ACSDGraphic;

enum
   {
	MATCH_KEYS = 0,
	MATCH_SIMILAR = 1
   };


@interface ArchiveTextDelegate : ArchiveDelegate
   {
	id styles;
	int styleMatching;
	id defaultStyle;
	ACSDGraphic *enclosingGraphic;
   }
+(ArchiveTextDelegate*)archiveTextDelegateWithType:(int)ty styleMatching:(int)stm styles:(id)sts document:(ACSDrawDocument*)doc enclosingGraphic:(ACSDGraphic*)eg;
-(id)initWithType:(int)ty styleMatching:(int)stm styles:(id)sts document:(ACSDrawDocument*)doc enclosingGraphic:(ACSDGraphic*)eg;

@end
