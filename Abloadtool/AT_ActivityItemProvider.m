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
    NSString *tmpURL = [NSString stringWithFormat:@"%@/img/%@", cURL_BASE, self.imageName];
    NSData* tmpData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:tmpURL]];
    UIImage *image = [[UIImage alloc] initWithData:tmpData];
    return image;
}

- (UIImage *)activityViewController:(UIActivityViewController *)activityViewController thumbnailImageForActivityType:(NSString *)activityType suggestedSize:(CGSize)size {
    NSString *tmpURL = [NSString stringWithFormat:@"%@/mini/%@", cURL_BASE, self.imageName];
    NSData* tmpData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:tmpURL]];
    UIImage *image = [[UIImage alloc] initWithData:tmpData];
    return image;
}

@end
