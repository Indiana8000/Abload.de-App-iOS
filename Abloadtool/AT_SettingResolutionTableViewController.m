//
//  AT_SettingResolutionTableViewController.m
//  Abloadtool
//
//  Created by Andreas Kreisl on 29.11.17.
//  Copyright © 2017 Andreas Kreisl. All rights reserved.
//

#define cResolutionCell @"ResolutionTableViewCell"

#import "AT_SettingResolutionTableViewController.h"

@interface AT_SettingResolutionTableViewController ()

@end

@implementation AT_SettingResolutionTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Init Navigation
    self.navigationItem.title = NSLocalizedString(@"nav_title_resolution", @"Navigation");
    
    // Init Data
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"resolutions" ofType:@"plist"];
    self.listResolutions = [NSArray arrayWithContentsOfFile:plistPath];

    // Init TableView
    [self.tableView registerClass:UITableViewCell.self forCellReuseIdentifier:cResolutionCell];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.listResolutions count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[[self.listResolutions objectAtIndex:section] objectForKey:@"list"] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [[self.listResolutions objectAtIndex:section] objectForKey:@"name"];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cResolutionCell forIndexPath:indexPath];
    cell.separatorInset = UIEdgeInsetsZero;
    
    cell.textLabel.text = [[[self.listResolutions objectAtIndex:[indexPath section]] objectForKey:@"list"] objectAtIndex:[indexPath row]];
    
    if([cell.textLabel.text compare:[[NetworkManager sharedManager] selectedResolution]] == NSOrderedSame)
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    else
        cell.accessoryType = UITableViewCellAccessoryNone;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [[NetworkManager sharedManager] saveSelectedResolution:[[[self.listResolutions objectAtIndex:[indexPath section]] objectForKey:@"list"] objectAtIndex:[indexPath row]]];
    [self.navigationController popViewControllerAnimated:YES];
}



@end
