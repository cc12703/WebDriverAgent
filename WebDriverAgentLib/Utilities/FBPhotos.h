//
//  FBPhotos.h
//  WebDriverAgent
//
//  Created by wzl on 2024/3/5.
//  Copyright © 2024 Facebook. All rights reserved.
//

#ifndef FBPhotos_h
#define FBPhotos_h


#import "FBImageUtils.h"
#import "FBErrorBuilder.h"
#import "FBAuthorization.h"

#import <Photos/Photos.h>


NS_ASSUME_NONNULL_BEGIN

@interface FBPhotos : NSObject

+ (BOOL)saveMedia: (nonnull NSData *)data type:(nonnull NSString *)type album: (nullable NSString *)albumName error:(NSError *__autoreleasing*)error;

+ (BOOL)deleteAlbum: (nonnull NSString *)name error:(NSError *__autoreleasing*)error;

+ (NSInteger)getPhotosNumberFromAlbum: (nonnull NSString *)name error:(NSError *__autoreleasing*)error;

@end

NS_ASSUME_NONNULL_END


#endif /* FBPhotos_h */

