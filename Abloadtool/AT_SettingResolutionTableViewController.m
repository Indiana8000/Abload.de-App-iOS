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
    //[self.tableView registerClass:UITableViewCell.self forCellReuseIdentifier:cResolutionCell];
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
    //UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cResolutionCell forIndexPath:indexPath];
    //cell.separatorInset = UIEdgeInsetsZero;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cResolutionCell];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cResolutionCell];
        cell.separatorInset = UIEdgeInsetsZero;
        cell.detailTextLabel.textAlignment = NSTextAlignmentLeft;
    }
    
    if(indexPath.section == 0 && indexPath.row == 0) {
        cell.textLabel.text = NSLocalizedString(@"label_keeporiginal", @"Settings");
        cell.detailTextLabel.text = @"";
    } else {
        NSArray* resolutionString = [[[[self.listResolutions objectAtIndex:[indexPath section]] objectForKey:@"list"] objectAtIndex:indexPath.row] componentsSeparatedByString:@" "];
        cell.textLabel.text = [resolutionString objectAtIndex:0];
        if([resolutionString count] > 2) {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@", [resolutionString objectAtIndex:1], [resolutionString objectAtIndex:2]];
        } else if([resolutionString count] > 1) {
            cell.detailTextLabel.text = [resolutionString objectAtIndex:1];
        } else {
            cell.detailTextLabel.text = @"";
        }
    }
    
    if([cell.textLabel.text compare:[[NetworkManager sharedManager] selectedResolution]] == NSOrderedSame)
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    else
        cell.accessoryType = UITableViewCellAccessoryNone;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0 && indexPath.row == 0) {
        [[NetworkManager sharedManager] saveSelectedResolution:NSLocalizedString(@"label_keeporiginal", @"Settings")];
    } else {
        NSArray* resolutionString = [[[[self.listResolutions objectAtIndex:[indexPath section]] objectForKey:@"list"] objectAtIndex:indexPath.row] componentsSeparatedByString:@" "];
        [[NetworkManager sharedManager] saveSelectedResolution:[resolutionString objectAtIndex:0]];
    }
    [self.navigationController popViewControllerAnimated:YES];
}



@end
