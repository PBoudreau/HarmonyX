//
//  FSCFunction.h
//
//  Created by Philippe Boudreau on 2014-11-09
//  Copyright (c) 2014 Fasterre services-conseils inc.. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface FSCFunction : NSObject <NSCoding, NSCopying>

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *action;
@property (nonatomic, strong) NSString *label;

+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

@end
