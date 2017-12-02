//
//  AT_SettingGalleryTableViewController.m
//  Abloadtool
//
//  Created by Andreas Kreisl on 10.11.17.
//  Copyright © 2017 Andreas Kreisl. All rights reserved.
//

#import "AT_SettingGalleryTableViewController.h"
#import <AFNetworking/UIImageView+AFNetworking.h>
#import "NetworkManager.h"

@interface AT_SettingGalleryTableViewController ()

@end

@implementation AT_SettingGalleryTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = NSLocalizedString(@"Gallery", @"Settings");
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GalleryListCell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"GalleryListCell"];
    }
    
    if(indexPath.section == 0) {
        cell.textLabel.text = NSLocalizedString(@"No Gallery", @"Settings");
        cell.detailTextLabel.text = nil;
    } else {
        cell.textLabel.text = [[[[NetworkManager sharedManager] gallery] objectAtIndex:indexPath.row] objectForKey:@"_name"];
        cell.detailTextLabel.text = [[[[NetworkManager sharedManager] gallery] objectAtIndex:indexPath.row] objectForKey:@"_desc"];
        
        NSString *tmpURL = [NSString stringWithFormat:@"https://www.abload.de/mini/%@", [[[[NetworkManager sharedManager] gallery] objectAtIndex:indexPath.row] objectForKey:@"_cover"]];
        [cell.imageView setImageWithURL:[NSURL URLWithString:tmpURL] placeholderImage:[UIImage imageNamed:@"AppIcon"]];
        [cell.imageView setFrame:CGRectMake(0, 0, 160, 160)];
    }

    // TBD
    //if( ??? ) cell.accessoryType = UITableViewCellAccessoryCheckmark;
    //else cell.accessoryType = UITableViewCellAccessoryNone;
    
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
