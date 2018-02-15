//
//  AT_SettingTableViewController.m
//  Abloadtool
//
//  Created by Andreas Kreisl on 10.11.17.
//  Copyright © 2017 Andreas Kreisl. All rights reserved.
//

#define cSettingsCell @"settingsTableViewCell"

#import "AT_SettingTableViewController.h"

@interface AT_SettingTableViewController ()

@end

@implementation AT_SettingTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = NSLocalizedString(@"nav_title_settings", @"Navigation");
}

- (void)viewWillAppear:(BOOL)animated {
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if((section == 1) && ([[[NetworkManager sharedManager] selectedResolution] compare:NSLocalizedString(@"label_keeporiginal", @"Settings")] != NSOrderedSame)) {
        return 2;
    } else {
        return 1;
    }
}

/*
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 0) {
        return NSLocalizedString(@"title_settings_upload", @"Settings");
    } else if(section == 2) {
        return NSLocalizedString(@"title_settings_other", @"Settings");
    } else {
        return nil;
    }
}
 */

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cSettingsCell];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cSettingsCell];
        cell.separatorInset = UIEdgeInsetsZero;
    }
    
    switch (indexPath.section) {
        case 0: {
            cell.textLabel.text = NSLocalizedString(@"label_gallery",@"Settings");
            if([[[NetworkManager sharedManager] selectedGallery] intValue] > 0) {
                long i = [[[NetworkManager sharedManager] gallery] indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    return ([[obj objectForKey:@"_id"] intValue] == [[[NetworkManager sharedManager] selectedGallery] intValue]);
                }];
                if(i < [[[NetworkManager sharedManager] gallery] count])
                    cell.detailTextLabel.text = [[[[NetworkManager sharedManager] gallery] objectAtIndex:i] objectForKey:@"_name"];
                else
                    cell.detailTextLabel.text = NSLocalizedString(@"label_nogallery", @"Settings");
            } else {
                cell.detailTextLabel.text = NSLocalizedString(@"label_nogallery", @"Settings");
            }
            }
            break;
        case 1: {
            if(indexPath.row == 0) {
                cell.textLabel.text = NSLocalizedString(@"label_resize",@"Settings");
                cell.detailTextLabel.text = [[NetworkManager sharedManager] selectedResolution];
            } else {
                cell.textLabel.text = NSLocalizedString(@"label_scale",@"Settings");
                cell.detailTextLabel.text = [[[[NetworkManager sharedManager] listScaling] objectAtIndex:[[[NetworkManager sharedManager] selectedScale] intValue]] objectAtIndex:0];
            }
            }
            break;
            /*
        case 2: {
            cell.textLabel.text = NSLocalizedString(@"label_linktype",@"Settings");
            cell.detailTextLabel.text = [[[[NetworkManager sharedManager] listOutputLinks] objectAtIndex:[[[NetworkManager sharedManager] selectedOutputLinks] intValue]] objectForKey:@"name"];
            }
            break;
             */
        default:
            cell.textLabel.text = @"Error Code: 2";
            break;
    }
    return cell;
}

#pragma mark - Table view delegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0: {
            AT_SettingGalleryTableViewController* tmpSGTC = [[AT_SettingGalleryTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
            [self.navigationController pushViewController:tmpSGTC animated:YES];
            }
            break;
        case 1:
            if(indexPath.row == 0) {
                AT_SettingResolutionTableViewController *tmpSRTC = [[AT_SettingResolutionTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
                [self.navigationController pushViewController:tmpSRTC animated:YES];
            } else {
                AT_SettingScaleTableViewController *tmpSSTC = [[AT_SettingScaleTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
                [self.navigationController pushViewController:tmpSSTC animated:YES];
            }
            break;
            /*
        case 2: {
            AT_SettingOutputLinksTableViewController *tmpOLTC = [[AT_SettingOutputLinksTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
            [self.navigationController pushViewController:tmpOLTC animated:YES];
            }
            break;
             */
    }
}



@end
