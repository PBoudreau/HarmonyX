//
//  FSCContent.h
//
//  Created by Philippe Boudreau on 2014-11-09
//  Copyright (c) 2014 Fasterre services-conseils inc.. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface FSCContent : NSObject <NSCoding, NSCopying>

@property (nonatomic, strong) NSString *contentServiceHost;
@property (nonatomic, strong) NSString *contentDeviceHost;
@property (nonatomic, strong) NSString *contentImageHost;
@property (nonatomic, strong) NSString *contentUserHost;
@property (nonatomic, strong) NSString *householdUserProfileUri;

+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

@end
