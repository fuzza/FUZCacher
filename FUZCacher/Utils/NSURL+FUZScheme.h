//
//  NSURL+FUZScheme.h
//  FUZCacher
//
//  Created by fuzza on 7/18/15.
//  Copyright (c) 2015 fuzza. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (FUZScheme)

- (NSURL *)fuz_urlWithScheme:(NSString *)scheme;

@end
