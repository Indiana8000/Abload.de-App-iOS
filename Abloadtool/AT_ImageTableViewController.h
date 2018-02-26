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
    @property NSString* gid;
    @property AT_DetailedViewController* detailedViewController;
    @property AT_SettingOutputLinksTableViewController* pageSetting;
    @property UINavigationController* navSetting;
    - (void)setLastRefresh;
@end
