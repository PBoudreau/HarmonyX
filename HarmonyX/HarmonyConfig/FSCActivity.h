//
//  FSCActivity.h
//
//  Created by Philippe Boudreau on 2014-11-09
//  Copyright (c) 2014 Fasterre services-conseils inc.. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FSCActivity : NSObject <NSCoding, NSCopying>

@property (nonatomic, strong) NSString *activityIdentifier;
@property (nonatomic, strong) NSString *baseImageUri;
@property (nonatomic, strong) NSString *label;
@property (nonatomic, strong) NSString *activityTypeDisplayName;
@property (nonatomic, strong) NSArray *controlGroup;
@property (nonatomic, strong) NSString *channelChangingActivityRole;
@property (nonatomic, strong) NSArray *sequences;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, assign) double activityOrder;
@property (nonatomic, strong) NSString *icon;
@property (nonatomic, assign) BOOL isTuningDefault;
@property (nonatomic, strong) NSString *suggestedDisplay;

+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

@end
