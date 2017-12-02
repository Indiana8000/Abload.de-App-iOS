//
//  AT_UploadTableViewController.h
//  Abloadtool
//
//  Created by Andreas Kreisl on 27.10.17.
//  Copyright © 2017 Andreas Kreisl. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AT_SettingTableViewController.h"

@interface AT_UploadTableViewController : UITableViewController <UIPopoverPresentationControllerDelegate, UIImagePickerControllerDelegate>
    @property (nonatomic, strong) AT_SettingTableViewController* pageSetting;
    @property (nonatomic, strong) UINavigationController* navSetting;
@end
