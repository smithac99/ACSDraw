//
//  ArchiveDelegate.h
//  ACSDraw
//
//  Created by alan on 07/02/07.
//  Copyright 2007 Alan C Smith. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class ACSDrawDocument;
@class KeyedObject;
@class ACSDLink;

enum
   {
	ARCHIVE_FILE = 0,
	ARCHIVE_PASTEBOARD = 1
   };

@interface ArchiveDelegate : NSObject<NSKeyedUnarchiverDelegate,NSKeyedArchiverDelegate>
   {
	int archiveType;
	ACSDrawDocument *document;
	BOOL sameDocument;
	NSMutableSet *newFills,*newStrokes,*newShadows,*newLineEndings;
   }

+(ArchiveDelegate*)archiveDelegateWithType:(int)ty document:(ACSDrawDocument*)doc;
-(id)initWithType:(int)ty document:(ACSDrawDocument*)doc;
-(int)archiveType;
-(void)registerObject:(KeyedObject*)ko;
-(BOOL)sameDocument;
-(void)setSameDocument:(BOOL)b;
-(NSMutableSet*)newFills;
-(NSMutableSet*)newStrokes;
-(NSMutableSet*)newShadows;
-(NSMutableSet*)newLineEndings;
-(id)matchLink:(ACSDLink*)link;

@end
