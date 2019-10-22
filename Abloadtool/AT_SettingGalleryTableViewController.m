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
        return [[[NetworkManager sharedManager] galleryList] count];
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
        cell.textLabel.text = [[[[NetworkManager sharedManager] galleryList] objectAtIndex:indexPath.row] objectForKey:@"_name"];
        //cell.textLabel.text = [[NSString alloc] initWithData:[[[[[NetworkManager sharedManager] galleryList] objectAtIndex:indexPath.row] objectForKey:@"_name"] dataUsingEncoding:NSUTF8StringEncoding] encoding:NSNonLossyASCIIStringEncoding];
        if([[[[[NetworkManager sharedManager] galleryList] objectAtIndex:indexPath.row] objectForKey:@"_desc"] length] > 0) {
            cell.detailTextLabel.text = [[[[NetworkManager sharedManager] galleryList] objectAtIndex:indexPath.row] objectForKey:@"_desc"];
            //cell.detailTextLabel.text = [[NSString alloc] initWithData:[[[[[NetworkManager sharedManager] galleryList] objectAtIndex:indexPath.row] objectForKey:@"_desc"] dataUsingEncoding:NSUTF8StringEncoding] encoding:NSNonLossyASCIIStringEncoding];
        } else {
            cell.detailTextLabel.text = @" ";
        }
        cell.dateTextLabel.text = [[[[[NetworkManager sharedManager] galleryList] objectAtIndex:indexPath.row] objectForKey:@"_lastchange"] substringToIndex:16];
        
        NSString *tmpURL = [NSString stringWithFormat:@"%@/%@/%@", cURL_BASE, [[NetworkManager sharedManager] getThumbPath], [[[[NetworkManager sharedManager] galleryList] objectAtIndex:indexPath.row] objectForKey:@"_thumb"]];
        [cell.imageView setImageWithURL:[NSURL URLWithString:tmpURL] placeholderImage:[UIImage imageNamed:@"AppIcon"]];
    }

    if(((indexPath.section == 1) && ([[NetworkManager sharedManager] settingGallerySelected] == [[[[[NetworkManager sharedManager] galleryList] objectAtIndex:indexPath.row] objectForKey:@"_id"] intValue])) || ((indexPath.section == 0) && ([[NetworkManager sharedManager] settingGallerySelected] == 0)))
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    else
        cell.accessoryType = UITableViewCellAccessoryNone;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0) {
        [[NetworkManager sharedManager] saveGallerySelected:0];
    } else {
        [[NetworkManager sharedManager] saveGallerySelected:[[[[[NetworkManager sharedManager] galleryList] objectAtIndex:indexPath.row] objectForKey:@"_id"] integerValue]];
    }
    [self.navigationController popViewControllerAnimated:YES];
}



@end
