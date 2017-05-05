//
//  RCTQRCodeLocalImage.m
//  RCTQRCodeLocalImage
//
//  Created by fangyunjiang on 15/11/4.
//  Copyright (c) 2015年 remobile. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <React/RCTLog.h>
#import <React/RCTUtils.h>
#import "RCTQRCodeLocalImage.h"
#import <AssetsLibrary/AssetsLibrary.h>

@implementation RCTQRCodeLocalImage
RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(decode:(NSString *)path callback:(RCTResponseSenderBlock)callback)
{
    
//    UIImage *srcImage;
//    if ([path hasPrefix:@"http://"] || [path hasPrefix:@"https://"]) {
//        srcImage = [UIImage imageWithData: [NSData dataWithContentsOfURL:[NSURL URLWithString: path]]];
//    } else {
//        srcImage = [[UIImage alloc] initWithContentsOfFile:path];
//    }
    
    ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *myasset)
    {
        ALAssetRepresentation *rep = [myasset defaultRepresentation];
        float width = [rep dimensions].width;
        float height = [rep dimensions].height;
        CGImageRef iref = CGImageCreateWithImageInRect([rep fullResolutionImage], CGRectMake(width/2, 0, width/2, height));
        
        if (nil==rep){
            NSLog(@"PROBLEM! IMAGE NOT LOADED\n");
            callback(@[RCTMakeError(@"IMAGE NOT LOADED!", nil, nil)]);
            return;
        }
        
        // Write image to test

//        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//        NSString *fileName = [rep filename];
//        NSString *combined = [NSString stringWithFormat:@"ScreenShot - %@.png", fileName];
//        NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:combined];
//        
//        UIImage *currentImage = [UIImage imageWithCGImage:iref];
//        NSData *currentImageData = UIImagePNGRepresentation(currentImage);
//        [currentImageData writeToFile:filePath atomically:YES];
        
        NSLog(@"OK - IMAGE LOADED\n");
        NSDictionary *detectorOptions = @{@"CIDetectorAccuracy": @"CIDetectorAccuracyHigh"};
        CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:detectorOptions];
        CIImage *image = [CIImage imageWithCGImage:iref];
        NSArray *features = [detector featuresInImage:image];
        if (0==features.count) {
            NSLog(@"PROBLEM! Feature size is zero!\n");
            callback(@[RCTMakeError(@"Feature size is zero!", nil, nil)]);
            return;
        }
        
        CIQRCodeFeature *feature = [features firstObject];
        
        NSString *result = feature.messageString;
        NSLog(@"result: %@", result);
        
        if (result) {
            callback(@[[NSNull null], result]);
        } else {
            callback(@[RCTMakeError(@"QR Parse failed!", nil, nil)]);
            return;
        }
    };
    
    ALAssetsLibraryAccessFailureBlock failureblock  = ^(NSError *myerror){
        
        //failed to get image.
    };
    
    ALAssetsLibrary* assetslibrary = [[ALAssetsLibrary alloc] init];
    NSURL *myAssetUrl = [NSURL URLWithString:[path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    [assetslibrary assetForURL:myAssetUrl resultBlock:resultblock failureBlock:failureblock];
}

@end
