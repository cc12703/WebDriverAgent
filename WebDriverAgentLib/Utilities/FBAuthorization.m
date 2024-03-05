//
//  FBAuthorization.m
//  WebDriverAgentLib
//
//  Created by wzl on 2024/2/29.
//  Copyright © 2024 Facebook. All rights reserved.
//

#import "FBAuthorization.h"


@implementation FBAuthorization

+ (BOOL)checkAddPhotosAuthorization
{
  PHAuthorizationStatus authorizationStatus = [PHPhotoLibrary authorizationStatus];
  return authorizationStatus == PHAuthorizationStatusAuthorized;
}

+ (void)requstAddPhotosAuthorization
{
  PHAuthorizationStatus authorizationStatus = [PHPhotoLibrary authorizationStatus];
  if(authorizationStatus == PHAuthorizationStatusNotDetermined) {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status){
      if(status != PHAuthorizationStatusAuthorized) {
        NSLog(@"photos request authorization fail.");
      }
    }];
  }
  else {
    NSLog(@"current authorization status: %ld", authorizationStatus);
  }
}


+ (BOOL)checkNetworkAuthorization
{
  SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(NULL, "http://www.baidu.com");
  SCNetworkReachabilityFlags flags;
  
  BOOL isSucc = SCNetworkReachabilityGetFlags(reachability, &flags);
  CFRelease(reachability);
  return isSucc;
}

+ (void)requestNetworkAuthorization
{
  NSLog(@"start request network authorization.");
  NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.baidu.com"]];
  NSURLSession *session = [NSURLSession sharedSession];
  NSURLSessionTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
    if (error == nil) {
      NSLog(@"requests network success。");
    }
  }];
  [dataTask resume];
}

@end

