//
//  NSString+StringAdditions.h
//  ACSDraw
//
//  Created by Alan on 15/07/2013.
//
//

#import <Foundation/Foundation.h>

@interface NSString (StringAdditions)

-(BOOL)containsChar:(unichar)uc;
-(BOOL)isNumeric;
- (NSComparisonResult)caseInsensitiveCompareWithNumbers:(NSString *)aString;
-(NSArray *)nonBlankComponentsSeparatedByString:(NSString *)separator;
-(NSArray *)nonBlankComponentsSeparatedByCharactersInSet:(NSCharacterSet *)separator;

@end
