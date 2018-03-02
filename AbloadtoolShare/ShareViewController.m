//
//  ShareViewController.m
//  AbloadtoolShare
//
//  Created by Andreas Kreisl on 15.02.18.
//  Copyright © 2018 Andreas Kreisl. All rights reserved.
//

#import "ShareViewController.h"

@interface ShareViewController ()

@end

@implementation ShareViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Abloadtool", @"Abloadtool");
    //self.textView.editable = NO;
    
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        // TODO: unknown
    }];
}

- (BOOL)isContentValid {
    return YES;
}

- (void)didSelectPost {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.de.bluepaw.Abloadtool"];
    
    NSURL* securityPath = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.de.bluepaw.Abloadtool"];
    NSString* filePath = [[securityPath path] stringByAppendingPathComponent:@"images"];
    if(![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    if(securityPath) {
        PHFetchOptions *options = [[PHFetchOptions alloc] init];
        options.includeHiddenAssets = YES;
        _assetsFetchResults = [PHAsset fetchAssetsWithOptions:options];
        _imageManager = [[PHCachingImageManager alloc] init];
        _imageList = [[NSMutableDictionary alloc] init];
        for(PHAsset* asset in _assetsFetchResults) {
            [_imageList setObject:asset forKey:[asset valueForKey:@"filename"]];
        }

        NSExtensionItem* extensionItem = self.extensionContext.inputItems[0];
        for(NSItemProvider* itemProvider in extensionItem.attachments) {
            if ([itemProvider hasItemConformingToTypeIdentifier:itemProvider.registeredTypeIdentifiers.firstObject]) {
                [itemProvider loadItemForTypeIdentifier:itemProvider.registeredTypeIdentifiers.firstObject options:nil completionHandler:^(id<NSSecureCoding> item, NSError *error) {
                    NSData* imgData = nil;
                    if( [(NSObject*)item isKindOfClass:[NSURL class]]) {
                        //imgData = [NSData dataWithContentsOfURL:(NSURL*)item];
                        imgData = [self fetchImage:[[(NSURL*)item pathComponents] lastObject]];
                    } else if( [(NSObject*)item isKindOfClass:[UIImage class]]) {
                        imgData = UIImageJPEGRepresentation((UIImage*)item, 0.85);
                    } else if( [(NSObject*)item isKindOfClass:[NSData class]]) {
                        imgData = (NSData*)item;
                    }
                    if(imgData != nil) {
                        NSInteger shareCount;
                        if([defaults integerForKey:@"share_count"]) {
                            shareCount = [defaults integerForKey:@"share_count"] +1;
                        } else {
                            shareCount = 1;
                        }
                        
                        NSString* fileName = [filePath stringByAppendingPathComponent:[NSString stringWithFormat:@"shared.%ld.jpeg", shareCount]];
                        [imgData writeToFile:fileName atomically:YES];

                        [defaults setInteger:shareCount forKey:@"share_count"];
                        [defaults synchronize];
                        
                    }
                }];
            }
        }
        [self showMessage:[NSString stringWithFormat:NSLocalizedString(@"share_msg_done %ld", @"ShareExtension"), extensionItem.attachments.count]];
    } else {
        // TODO: Error cant send Pictures!
    }
}

- (NSArray *)configurationItems {
    return @[];
}

- (NSData*)fetchImage:(NSString*) filename {
    if([_imageList objectForKey:filename]) {
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        options.synchronous = YES;
        options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        
        __block NSData* tmp = nil;
        [_imageManager requestImageDataForAsset:[_imageList objectForKey:filename] options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
            tmp = imageData;
        }];
        return tmp;
    } else {
        return nil;
    }
}

- (void)showMessage:(NSString*) msg {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:msg
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"btn_ok", @"Abloadtool") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];

    }];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}



@end
