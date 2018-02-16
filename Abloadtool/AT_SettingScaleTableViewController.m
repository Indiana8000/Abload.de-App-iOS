//
//  AT_SettingScaleTableViewController.m
//  Abloadtool
//
//  Created by Andreas Kreisl on 29.11.17.
//  Copyright © 2017 Andreas Kreisl. All rights reserved.
//

#define cScaleCell @"ScalingTableViewCell"

#import "AT_SettingScaleTableViewController.h"

@interface AT_SettingScaleTableViewController ()

@end

@implementation AT_SettingScaleTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Init Navigation
    self.navigationItem.title = NSLocalizedString(@"nav_title_scaling", @"Navigation");
    
    // Init TableView
    [self.tableView registerClass:UITableViewCell.self forCellReuseIdentifier:cScaleCell];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[[NetworkManager sharedManager] settingAvailableScalingList] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return [[[[NetworkManager sharedManager] settingAvailableScalingList] objectAtIndex:section] objectAtIndex:1];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cScaleCell forIndexPath:indexPath];
    cell.separatorInset = UIEdgeInsetsZero;
    
    cell.textLabel.text = [[[[NetworkManager sharedManager] settingAvailableScalingList] objectAtIndex:indexPath.section] objectAtIndex:0];

    if([[NetworkManager sharedManager] settingScaleSelected] == indexPath.section)
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    else
        cell.accessoryType = UITableViewCellAccessoryNone;
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [[NetworkManager sharedManager] saveScaleSelected:indexPath.section];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
