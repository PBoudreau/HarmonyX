//
//  FSCDevice.h
//
//  Created by Philippe Boudreau on 2014-11-09
//  Copyright (c) 2014 Fasterre services-conseils inc.. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface FSCDevice : NSObject <NSCoding, NSCopying>

@property (nonatomic, strong) NSString *deviceIdentifier;
@property (nonatomic, strong) NSString *label;
@property (nonatomic, strong) NSString *deviceProfileUri;
@property (nonatomic, assign) BOOL isKeyboardAssociated;
@property (nonatomic, assign) double controlPort;
@property (nonatomic, strong) NSArray *controlGroup;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *isManualPower;
@property (nonatomic, assign) double dongleRFID;
@property (nonatomic, strong) NSArray *capabilities;
@property (nonatomic, assign) double transport;
@property (nonatomic, strong) NSString *deviceTypeDisplayName;
@property (nonatomic, strong) NSString *manufacturer;
@property (nonatomic, strong) NSString *suggestedDisplay;
@property (nonatomic, strong) NSString *model;
@property (nonatomic, strong) NSString *icon;

+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

@end
