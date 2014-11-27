//
//  FSCControlGroup.h
//
//  Created by Philippe Boudreau on 2014-11-09
//  Copyright (c) 2014 Fasterre services-conseils inc.. All rights reserved.
//

#import <Foundation/Foundation.h>

@class  FSCFunction;

@interface FSCControlGroup : NSObject <NSCoding, NSCopying>

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSArray *function;

+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

- (FSCFunction *) functionNamed: (NSString *) functionName;
- (FSCFunction *) volumeDownFunction;
- (FSCFunction *) volumeUpFunction;
- (FSCFunction *) playFunction;
- (FSCFunction *) pauseFunction;
- (FSCFunction *) skipBackwardFunction;
- (FSCFunction *) skipForwardFunction;

@end
