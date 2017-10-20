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
#import <Photos/Photos.h>
#import "RCTQRCodeLocalImage.h"

@implementation RCTQRCodeLocalImage
RCT_EXPORT_MODULE()

- (void)loadImageWithPath:(NSString *)path callback:(void(^)(UIImage * _Nullable srcImage))callback {
    if ([path hasPrefix:@"http://"] || [path hasPrefix:@"https://"]) {
        callback([UIImage imageWithData: [NSData dataWithContentsOfURL:[NSURL URLWithString: path]]]);
    } else if ([path hasPrefix:@"assets-library://"]) {
        PHFetchResult *results = [PHAsset fetchAssetsWithALAssetURLs:@[[NSURL URLWithString:path]] options:nil];
        PHAsset *asset = [results firstObject];
        PHImageRequestOptions *imageOptions = [PHImageRequestOptions new];
        imageOptions.networkAccessAllowed = YES;
        imageOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        imageOptions.resizeMode = PHImageRequestOptionsResizeModeNone;
        
        [[PHImageManager defaultManager] requestImageDataForAsset:asset
                                                          options:imageOptions
                                                    resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                                                        if (imageData == nil) {
                                                            callback(nil);
                                                        } else {
                                                            callback([UIImage imageWithData:imageData]);
                                                        }
                                                    }];
    } else {
        callback([[UIImage alloc] initWithContentsOfFile:path]);
    }
}

RCT_EXPORT_METHOD(decode:(NSString *)path callback:(RCTResponseSenderBlock)callback)
{
    [self loadImageWithPath:path callback:^(UIImage * _Nullable srcImage) {
        if (nil==srcImage){
            NSLog(@"PROBLEM! IMAGE NOT LOADED\n");
            callback(@[RCTMakeError(@"IMAGE NOT LOADED!", nil, nil)]);
            return;
        }
        NSLog(@"OK - IMAGE LOADED\n");
        
        NSDictionary *detectorOptions = @{@"CIDetectorAccuracy": @"CIDetectorAccuracyHigh"};
        CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:detectorOptions];
        CIImage *image = [CIImage imageWithCGImage:srcImage.CGImage];
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
    }];
}
@end
