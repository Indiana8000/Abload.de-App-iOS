//
//  AT_ImageTableViewController.h
//  Abloadtool
//
//  Created by Andreas Kreisl on 10.01.18.
//  Copyright © 2018 Andreas Kreisl. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AFNetworking/UIImageView+AFNetworking.h>

#import "NetworkManager.h"
#import "AT_ImageTableViewCell.h"
#import "AT_DetailedViewController.h"
#import "AT_SettingOutputLinksTableViewController.h"

@interface AT_ImageTableViewController : UITableViewController
    @property (nonatomic) NSString* gid;
    @property (nonatomic, strong) AT_DetailedViewController* detailedViewController;
    @property (nonatomic, strong) AT_SettingOutputLinksTableViewController* pageSetting;
    @property (nonatomic, strong) UINavigationController* navSetting;
@end
