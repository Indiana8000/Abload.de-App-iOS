//
//  AT_SettingResolutionTableViewController.m
//  Abloadtool
//
//  Created by Andreas Kreisl on 29.11.17.
//  Copyright © 2017 Andreas Kreisl. All rights reserved.
//

#define c_RCELLID @"ResolutionTableViewCell"

#import "AT_SettingResolutionTableViewController.h"
#import "NetworkManager.h"

@interface AT_SettingResolutionTableViewController ()

@end

@implementation AT_SettingResolutionTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = NSLocalizedString(@"Resolution", @"Settings");
    
    NSLog(@"PATH: %@",[[NSBundle mainBundle] bundlePath] );
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"resolutions" ofType:@"plist"];
    self.listResolutions = [NSArray arrayWithContentsOfFile:plistPath];

    [self.tableView registerClass:UITableViewCell.self forCellReuseIdentifier:c_RCELLID];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.listResolutions count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[[self.listResolutions objectAtIndex:section] objectForKey:@"list"] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [[self.listResolutions objectAtIndex:section] objectForKey:@"name"];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:c_RCELLID forIndexPath:indexPath];
    
    cell.textLabel.text = [[[self.listResolutions objectAtIndex:[indexPath section]] objectForKey:@"list"] objectAtIndex:[indexPath row]];
    
    if([cell.textLabel.text compare:[[NetworkManager sharedManager] selectedResolution]] == NSOrderedSame) cell.accessoryType = UITableViewCellAccessoryCheckmark;
    else cell.accessoryType = UITableViewCellAccessoryNone;
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [[NetworkManager sharedManager] saveSelectedResolution:[[[self.listResolutions objectAtIndex:[indexPath section]] objectForKey:@"list"] objectAtIndex:[indexPath row]]];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
