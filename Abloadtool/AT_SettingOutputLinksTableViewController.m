//
//  AT_SettingOutputLinksTableViewController.m
//  Abloadtool
//
//  Created by Andreas Kreisl on 18.01.18.
//  Copyright © 2018 Andreas Kreisl. All rights reserved.
//

#define cOLinksCell @"OLinksTableViewCell"

#import "AT_SettingOutputLinksTableViewController.h"

@interface AT_SettingOutputLinksTableViewController ()

@end

@implementation AT_SettingOutputLinksTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Init Navigation
    self.navigationItem.title = NSLocalizedString(@"Link Types", @"Settings");
    
    // Init TableView
    [self.tableView registerClass:UITableViewCell.self forCellReuseIdentifier:cOLinksCell];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[[NetworkManager sharedManager] listOutputLinks] count];;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cOLinksCell forIndexPath:indexPath];
    cell.separatorInset = UIEdgeInsetsZero;
    
    cell.textLabel.text = [[[[NetworkManager sharedManager] listOutputLinks] objectAtIndex:indexPath.row] objectForKey:@"name"];
    
    if([[[NetworkManager sharedManager] selectedOutputLinks] longLongValue] == indexPath.row)
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    else
        cell.accessoryType = UITableViewCellAccessoryNone;
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [[NetworkManager sharedManager] saveSelectedOutputLinks:[NSNumber numberWithLong:indexPath.row]];
    [self.navigationController popViewControllerAnimated:YES];
}


@end
