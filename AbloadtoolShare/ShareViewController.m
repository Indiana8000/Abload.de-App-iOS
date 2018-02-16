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
    self.title = NSLocalizedString(@"Abloadtool", @"Abloadtool");
    self.textView.editable = NO;
    
    NSLog(@"extensionContext: %@", self.extensionContext);
}

- (BOOL)isContentValid {
    return YES;
}

- (void)didSelectPost {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.de.bluepaw.Abloadtool"];
    
    NSFileManager* fileManager = [[NSFileManager alloc] init];
    NSURL* securityPath = [fileManager containerURLForSecurityApplicationGroupIdentifier:@"group.de.bluepaw.Abloadtool"];
    NSLog(@"DEBUG - securityPath :: %@", securityPath);

    NSString* filePath = [[securityPath path] stringByAppendingPathComponent:@"images"];
    if(![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSLog(@"DEBUG - filePath :: %@", filePath);

    if(securityPath) {
        NSExtensionItem* extensionItem = self.extensionContext.inputItems[0];
        for(NSItemProvider* itemProvider in extensionItem.attachments) {
            if([itemProvider hasItemConformingToTypeIdentifier:@"public.jpeg"]) {
                NSLog(@"itemProvider:\r\n%@", itemProvider);
                [itemProvider loadItemForTypeIdentifier:@"public.jpeg" options:nil completionHandler:^(id<NSSecureCoding>  _Nullable item, NSError * _Null_unspecified error) {
                    NSData* imgData = nil;
                    if( [(NSObject*)item isKindOfClass:[NSURL class]]) {
                        imgData = [NSData dataWithContentsOfURL:(NSURL*)item];
                    }
                    if( [(NSObject*)item isKindOfClass:[UIImage class]]) {
                        imgData = UIImageJPEGRepresentation((UIImage*)item, 0.85);
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
                        //NSURL* fileName = [securityPath URLByAppendingPathComponent:[NSString stringWithFormat:@"shared.%ld.jpeg", shareCount]];
                        //[imgData writeToURL:fileName atomically:YES];

                        NSLog(@"DEBUG - shareCount :: %ld", shareCount);
                        [defaults setInteger:shareCount forKey:@"share_count"];
                        [defaults synchronize];
                    }
                }];
            }
        }
    } else {
        // TODO: Error cant send Pictures!
    }

    [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
}

- (NSArray *)configurationItems {
    return @[];
}

@end
