//
//  AT_ActivityItemProvider.m
//  Abloadtool
//
//  Created by Andreas Kreisl on 23.03.18.
//  Copyright © 2018 Andreas Kreisl. All rights reserved.
//

#import "AT_ActivityItemProvider.h"

@implementation AT_ActivityItemProvider

- (id)activityViewControllerPlaceholderItem:(UIActivityViewController *)activityViewController {
    return [[UIImage alloc] init];
}

- (id)item {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NetworkManager sharedManager] showProgressHUDWithText:self.msg];
    });
    NSString *tmpURL = [NSString stringWithFormat:@"%@/img/%@", cURL_BASE, self.imageName];
    __block NSData* tmpData;
    dispatch_sync(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
        tmpData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:tmpURL]];
    });
    UIImage *image = [[UIImage alloc] initWithData:tmpData];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NetworkManager sharedManager] hideProgressHUD];
    });
    return image;
}

- (UIImage *)activityViewController:(UIActivityViewController *)activityViewController thumbnailImageForActivityType:(NSString *)activityType suggestedSize:(CGSize)size {
    NSString *tmpURL = [NSString stringWithFormat:@"%@/mini/%@", cURL_BASE, self.imageName];
    NSData* tmpData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:tmpURL]];
    UIImage *image = [[UIImage alloc] initWithData:tmpData];
    return image;
}

@end
