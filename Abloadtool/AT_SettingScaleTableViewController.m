//
//  AT_SettingScaleTableViewController.m
//  Abloadtool
//
//  Created by Andreas Kreisl on 29.11.17.
//  Copyright © 2017 Andreas Kreisl. All rights reserved.
//

#define c_SCELLID @"ScalingTableViewCell"

#import "AT_SettingScaleTableViewController.h"
#import "NetworkManager.h"

@interface AT_SettingScaleTableViewController ()

@end

@implementation AT_SettingScaleTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = NSLocalizedString(@"Scaling", @"Settings");
    
    [self.tableView registerClass:UITableViewCell.self forCellReuseIdentifier:c_SCELLID];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[[NetworkManager sharedManager] listScaling] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return [[[[NetworkManager sharedManager] listScaling] objectAtIndex:section] objectAtIndex:1];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:c_SCELLID forIndexPath:indexPath];
    
    cell.textLabel.text = [[[[NetworkManager sharedManager] listScaling] objectAtIndex:indexPath.section] objectAtIndex:0];

    if([[[NetworkManager sharedManager] selectedScale] longLongValue] == indexPath.section) cell.accessoryType = UITableViewCellAccessoryCheckmark;
    else cell.accessoryType = UITableViewCellAccessoryNone;
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [[NetworkManager sharedManager] saveSelectedScale:[NSNumber numberWithLong:indexPath.section]];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
