//
//  FSCHarmonyConfiguration.h
//
//  Created by Philippe Boudreau on 2014-11-09
//  Copyright (c) 2014 Fasterre services-conseils inc.. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FSCContent, FSCGlobal, FSCActivity;

@interface FSCHarmonyConfiguration : NSObject <NSCoding, NSCopying>

@property (nonatomic, strong) NSArray *activity;
@property (nonatomic, strong) NSArray *sequence;
@property (nonatomic, strong) NSArray *device;
@property (nonatomic, strong) FSCContent *content;
@property (nonatomic, strong) FSCGlobal *global;

+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

- (FSCActivity *) activityWithId: (NSString *) activityId;

@end
