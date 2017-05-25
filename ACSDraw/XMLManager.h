//
//  XMLManager.h
//  p-1-phonics
//
//  Created by Alan on 11/10/2013.
//  Copyright (c) 2013 Eurotalk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMLNode.h"

@interface XMLManager : NSObject<NSXMLParserDelegate>
{
    
}
@property (retain) NSMutableArray *nodes,*nodeStack;
@property (retain) NSXMLParser *xmlParser;
@property (retain) NSString *fileName;

-(XMLNode*)parseFile:(NSString*)filename;
-(XMLNode*)parseData:(NSData*)data;

@end
