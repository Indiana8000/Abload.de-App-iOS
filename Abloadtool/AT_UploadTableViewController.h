//
//  AT_UploadTableViewController.h
//  Abloadtool
//
//  Created by Andreas Kreisl on 27.10.17.
//  Copyright © 2017 Andreas Kreisl. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AFNetworking/UIImageView+AFNetworking.h>
#import "UzysAssetsPickerController.h"
#import "NetworkManager.h"

#import "AT_ImageTableViewCell.h"

#import "AT_SettingTableViewController.h"

@interface AT_UploadTableViewController : UITableViewController <UIPopoverPresentationControllerDelegate, UzysAssetsPickerControllerDelegate>
    @property (nonatomic, strong) AT_SettingTableViewController* pageSetting;
    @property (nonatomic, strong) UINavigationController* navSetting;
    @property (nonatomic, strong) UzysAssetsPickerController* uzysPicker;
@end
