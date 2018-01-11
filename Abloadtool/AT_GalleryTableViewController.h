//
//  AT_GalleryTableViewController.h
//  Abloadtool
//
//  Created by Andreas Kreisl on 19.10.17.
//  Copyright © 2017 Andreas Kreisl. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AFNetworking/UIImageView+AFNetworking.h>

#import "NetworkManager.h"
#import "AT_ImageTableViewCell.h"
#import "AT_ImageTableViewController.h"

@interface AT_GalleryTableViewController : UITableViewController
@property (nonatomic, strong) AT_ImageTableViewController* imageTableViewController;
@end
