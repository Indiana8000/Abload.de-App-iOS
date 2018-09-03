//
//  AT_DetailedViewController.h
//  Abloadtool
//
//  Created by Andreas Kreisl on 11.01.18.
//  Copyright © 2018 Andreas Kreisl. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import <AFNetworking/UIImageView+AFNetworking.h>

#import "NetworkManager.h"


@interface AT_DetailedViewController : UIViewController <UIScrollViewDelegate>
    @property UIScrollView* detailedScrollView;

    @property NSArray* imageList;
    @property NSInteger imageID;
    @property NSURL* imageURL;

    @property UIImageView* imageView;
@end
