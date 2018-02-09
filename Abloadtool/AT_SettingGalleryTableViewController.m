//
//  AT_SettingGalleryTableViewController.m
//  Abloadtool
//
//  Created by Andreas Kreisl on 10.11.17.
//  Copyright © 2017 Andreas Kreisl. All rights reserved.
//

#define cImageCell @"ImageTableViewCell"

#import "AT_SettingGalleryTableViewController.h"

@interface AT_SettingGalleryTableViewController ()

@end

@implementation AT_SettingGalleryTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Init Navigation
    self.navigationItem.title = NSLocalizedString(@"nav_title_uploadgallery", @"Navigation");

    // Init TableView
    [self.tableView registerClass:[AT_ImageTableViewCell class] forCellReuseIdentifier:cImageCell];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section == 0) {
        return 1;
    } else {
        return [[[NetworkManager sharedManager] gallery] count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    AT_ImageTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cImageCell forIndexPath:indexPath];
    cell.separatorInset = UIEdgeInsetsZero;
    
    if(indexPath.section == 0) {
        cell.textLabel.text = NSLocalizedString(@"label_nogallery", @"Settings");
        cell.detailTextLabel.text = @" ";
        cell.dateTextLabel.text = @" ";
        [cell.imageView setImage:[UIImage imageNamed:@"AppIcon"]];
    } else {
        cell.textLabel.text = [[[[NetworkManager sharedManager] gallery] objectAtIndex:indexPath.row] objectForKey:@"_name"];
        if([[[[[NetworkManager sharedManager] gallery] objectAtIndex:indexPath.row] objectForKey:@"_desc"] length] > 0) {
            cell.detailTextLabel.text = [[[[NetworkManager sharedManager] gallery] objectAtIndex:indexPath.row] objectForKey:@"_desc"];
        } else {
            cell.detailTextLabel.text = @" ";
        }
        cell.dateTextLabel.text = [[[[[NetworkManager sharedManager] gallery] objectAtIndex:indexPath.row] objectForKey:@"_lastchange"] substringToIndex:16];
        
        NSString *tmpURL = [NSString stringWithFormat:@"%@/mini/%@", cURL_BASE, [[[[NetworkManager sharedManager] gallery] objectAtIndex:indexPath.row] objectForKey:@"_thumb"]];
        [cell.imageView setImageWithURL:[NSURL URLWithString:tmpURL] placeholderImage:[UIImage imageNamed:@"AppIcon"]];
    }

    if(((indexPath.section == 1) && ([[[NetworkManager sharedManager] selectedGallery] intValue] == [[[[[NetworkManager sharedManager] gallery] objectAtIndex:indexPath.row] objectForKey:@"_id"] intValue])) || ((indexPath.section == 0) && ([[[NetworkManager sharedManager] selectedGallery] intValue] == 0)))
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    else
        cell.accessoryType = UITableViewCellAccessoryNone;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSNumber *gid;
    if(indexPath.section == 0) {
        gid = [NSNumber numberWithInt: 0];
    } else {
        gid = [NSNumber numberWithInt: [[[[[NetworkManager sharedManager] gallery] objectAtIndex:indexPath.row] objectForKey:@"_id"] intValue]];
    }
    [[NetworkManager sharedManager] saveSelectedGallery:gid];
    [self.navigationController popViewControllerAnimated:YES];
}



@end
