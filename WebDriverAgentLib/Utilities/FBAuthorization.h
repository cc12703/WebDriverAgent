//  FBAuthorization.h
//  WebDriverAgent
//
//  Created by wzl on 2024/2/29.
//  Copyright © 2024 Facebook. All rights reserved.
//

#ifndef FBAuthorization_h
#define FBAuthorization_h

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import <SystemConfiguration/SystemConfiguration.h>



NS_ASSUME_NONNULL_BEGIN

@interface FBAuthorization : NSObject

+ (BOOL)checkAddPhotosAuthorization;
+ (void)requstAddPhotosAuthorization;

+ (BOOL)checkNetworkAuthorization;
+ (void)requestNetworkAuthorization;

@end

NS_ASSUME_NONNULL_END


#endif /* FBAuthorization_h */
