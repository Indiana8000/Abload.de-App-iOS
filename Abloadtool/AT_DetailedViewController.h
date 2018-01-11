//
//  AT_DetailedViewController.h
//  Abloadtool
//
//  Created by Andreas Kreisl on 11.01.18.
//  Copyright © 2018 Andreas Kreisl. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AFNetworking/UIImageView+AFNetworking.h>

#import "NetworkManager.h"

@interface AT_DetailedViewController : UIViewController <UIScrollViewDelegate>
@property (nonatomic, strong) UIScrollView* detailedScrollView;
@property (nonatomic, strong) NSURL* imageURL;
@property (nonatomic, strong) UIImageView* imageView;
@end
