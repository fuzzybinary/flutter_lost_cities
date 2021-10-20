//
//  TorchModule.h
//  Runner
//
//  Created by Jeff Ward on 6/1/21.
//
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TorchModule : NSObject

@property(atomic, readonly) int objectId;

- (nullable instancetype)initWithFileAtPath:(NSString*)filePath objectId:(int)objectId
NS_SWIFT_NAME(init(fileAtPath:objectId:))NS_DESIGNATED_INITIALIZER;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (NSData*)executeWithData:(NSData*)data width:(int)width height:(int)height;
@end

NS_ASSUME_NONNULL_END
