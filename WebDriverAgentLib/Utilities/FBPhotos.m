//
//  FBPhotos.m
//  WebDriverAgentLib
//
//  Created by wzl on 2024/2/26.
//  Copyright © 2024 Facebook. All rights reserved.
//
#import "FBPhotos.h"


@implementation FBPhotos


+ (NSString *)saveImageFile:(nonnull NSData *)data
                      error:(NSError *__autoreleasing*)error
{
  NSString *fileName = [NSString stringWithFormat:@"m_%ld.png", (long)[[NSDate date] timeIntervalSince1970]];
  NSString *saveFilePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:fileName];
  
  NSData *imgData = FBToPngData(data);
  [UIImagePNGRepresentation([UIImage imageWithData:imgData]) writeToFile:saveFilePath options:NSAtomicWrite error:error];
  return saveFilePath;
}

+ (NSString *)saveVideoFile:(nonnull NSData *)data
                      error:(NSError *__autoreleasing*)error
{
  NSString *fileName = [NSString stringWithFormat:@"m_%ld.mp4", (long)[[NSDate date] timeIntervalSince1970]];
  NSString *saveFilePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:fileName];
  
  [[NSFileManager defaultManager] createFileAtPath:saveFilePath contents:data attributes:nil];
  return saveFilePath;
}

+ (NSString *)getMediaFromBase64Data:(NSString *)base64Data
                        type:(nonnull NSString *)type
                       error:(NSError *__autoreleasing*)error
{
  NSData *data = [[NSData alloc] initWithBase64EncodedString:base64Data options:NSDataBase64DecodingIgnoreUnknownCharacters];
  if(data == nil) {
    NSLog(@"save %@ fail, base64 encode fail.", type);
    [[[FBErrorBuilder builder] withDescription:@"base64 encode fail."] buildError:error];
    return nil;
  }
  
  if([type isEqualToString:@"image"]) {
    return [self saveImageFile:data error:error];
  }
  else if([type isEqualToString:@"video"]) {
    return [self saveVideoFile:data error:error];
  }
  else{
    NSString *failResponse = [NSString stringWithFormat:@"unsupport media type: %@", type];
    NSLog(@"%@", failResponse);
    [[[FBErrorBuilder builder] withDescription:failResponse] buildError:error];
    return nil;
  }
}

+ (nullable PHObjectPlaceholder *)saveMediaToAlbum: (nonnull NSString *)base64Data
                                             type:(nonnull NSString *)type
                                            error:(NSError *__autoreleasing*)error
{
  NSString *fileUrl = [self getMediaFromBase64Data:base64Data type:type error:error];
  NSLog(@"media temp path: %@", fileUrl);
  if(fileUrl == nil) {
    return nil;
  }
  
  __block PHObjectPlaceholder *placeholder = nil;
  [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
    if([type isEqualToString:@"image"]) {
      placeholder = [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:[NSURL URLWithString:fileUrl]].placeholderForCreatedAsset;
    }
    else if([type isEqualToString:@"video"]) {
      placeholder = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:[NSURL URLWithString:fileUrl]].placeholderForCreatedAsset;
    }
    else {
      NSString *failResponse = [NSString stringWithFormat:@"save media fail, unsupport media type: %@", type];
      NSLog(@"%@", failResponse);
      [[[FBErrorBuilder builder] withDescription:failResponse] buildError:error];
    }
  } error:error];
  
  return placeholder;
}

+ (BOOL)saveMediaToCustomAlbum:(nonnull NSString *)albumName
                  placeholder:(PHObjectPlaceholder *)placeholder
                        error:(NSError *__autoreleasing*)error
{
  PHAssetCollection *assetCollection = [self createAlbum:albumName error:error];
  if (assetCollection ==  nil) {
    NSLog(@"save media to custom album fail, create album: $@ fail.", albumName);
    return NO;
  }
  
  //将保存到系统相册的图片转到自定义相册，最新保存的图片排在最后面
  [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
    PHAssetCollectionChangeRequest *requetes = [PHAssetCollectionChangeRequest changeRequestForAssetCollection: assetCollection];
    [requetes addAssets:@[placeholder]];
  } error:error];
  
  NSLog(@"save media to custom album success.");
  return YES;
}


//避免重复创建一个相册
+(nullable PHAssetCollection *) createAlbum: (nonnull NSString *)name
                                      error:(NSError **)error
{
  PHFetchResult<PHAssetCollection *> *collections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
  
  PHAssetCollection *createCollection = nil;
  for(PHAssetCollection *collection in collections) {
    if([collection.localizedTitle isEqualToString: name]) {
      createCollection = collection;
      break;
    }
  }
  
  if(createCollection == nil) {
    __block NSString *createCollectionID = nil;
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
      createCollectionID = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:name].placeholderForCreatedAssetCollection.localIdentifier;
    } error:error];
    
    createCollection = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[createCollectionID] options:nil].firstObject;
  }
  
  return createCollection;
}


+(BOOL) saveMedia: (nonnull NSString *)data
             type:(nonnull NSString *)type
            album: (nullable NSString *)albumName
            error:(NSError *__autoreleasing*)error
{
  NSLog(@"start save media, type: %@, album: %@", type, albumName);
  if(![FBAuthorization checkAddPhotosAuthorization]) {
    NSLog(@"save image fail, not authorization, start authorization.");
    [[[FBErrorBuilder builder] withDescription:@"save image fail, not authorization"] buildError:error];
    return NO;
  }
  
  PHObjectPlaceholder *holder = [self saveMediaToAlbum:data type:type error:error];
  if(holder == nil) {
    NSLog(@"save media fail. error: %@", *error);
    return NO;
  }
  
  if([albumName length] > 0) {
    return [self saveMediaToCustomAlbum:albumName placeholder:holder error:error];
  }
  
  *error = nil;
  NSLog(@"save media success.");
  return YES;
}


+ (BOOL) deleteAlbum: (nonnull NSString *)name
              error:(NSError *__autoreleasing*)error
{
  NSLog(@"start delete album: %@", name);
  PHFetchResult<PHAssetCollection *> *collections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
  
  for(PHAssetCollection *collection in collections) {
    if([[collection localizedTitle] isEqualToString: name]) {
      PHFetchResult *assetResult = [PHAsset fetchAssetsInAssetCollection:collection options:[PHFetchOptions new]];
      [assetResult enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
//        同步删除，需要等待删除结果
//        [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
//          [PHAssetChangeRequest deleteAssets:@[obj]];
//        } error:error];
        
//      异步删除
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
          [PHAssetChangeRequest deleteAssets:@[obj]];
        } completionHandler: ^(BOOL success, NSError *error) {
          if(success) {
            NSLog(@"delete media succcess.");
          } else {
            NSLog(@"delete media failed.");
          }
        }];
        
        NSLog(@"delete album: %@ end", name);
      }];
    }
  }
  
  return *error == nil;
}


+ (NSInteger)getPhotosNumberFromAlbum: (nonnull NSString *)name error:(NSError *__autoreleasing*)error {
  PHFetchResult<PHAssetCollection *> *collections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];

  for(PHAssetCollection *collection in collections) {
    if([[collection localizedTitle] isEqualToString: name]) {
      PHFetchResult *assetResult = [PHAsset fetchAssetsInAssetCollection:collection options:[PHFetchOptions new]];
      NSInteger photosCount = [assetResult count];
      NSLog(@"album: %@  photos count: %ld.", name, photosCount);
      return photosCount;
    }
  }
  
  NSLog(@"not found album: %@", name);
  return 0;
}

@end


