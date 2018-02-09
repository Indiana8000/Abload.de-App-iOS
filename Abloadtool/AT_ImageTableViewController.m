//
//  AT_ImageTableViewController.m
//  Abloadtool
//
//  Created by Andreas Kreisl on 10.01.18.
//  Copyright © 2018 Andreas Kreisl. All rights reserved.
//

#define cImageCell @"ImageTableViewCell"

#import "AT_ImageTableViewController.h"

@interface AT_ImageTableViewController ()

@end

@implementation AT_ImageTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Init Navigation Controller + Buttons
    //self.navigationItem.title =
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"901-clipboard"] style:UIBarButtonItemStylePlain target:self action:@selector(doCopyLinks)];

    // Init TableView
    [self.tableView registerClass:[AT_ImageTableViewCell class] forCellReuseIdentifier:cImageCell];

    // Init detailedViewController
    self.detailedViewController = [[AT_DetailedViewController alloc] init];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void) viewWillAppear:(BOOL)animated {
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[[[NetworkManager sharedManager] imageList] objectForKey:self.gid] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    AT_ImageTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cImageCell forIndexPath:indexPath];
    cell.separatorInset = UIEdgeInsetsZero;
    cell.detailTextLabel.textAlignment = NSTextAlignmentRight;

    cell.textLabel.text = [[[[[NetworkManager sharedManager] imageList] objectForKey:self.gid] objectAtIndex:indexPath.row] objectForKey:@"_filename"];
    cell.detailTextLabel.text = [self bytesToUIString:[[[[[NetworkManager sharedManager] imageList] objectForKey:self.gid] objectAtIndex:indexPath.row] objectForKey:@"_filesize"]];
    cell.dateTextLabel.text = [[[[[[NetworkManager sharedManager] imageList] objectForKey:self.gid] objectAtIndex:indexPath.row] objectForKey:@"_date"] substringToIndex:16];

    NSString *tmpURL = [NSString stringWithFormat:@"%@/mini/%@", cURL_BASE, [[[[[NetworkManager sharedManager] imageList] objectForKey:self.gid] objectAtIndex:indexPath.row] objectForKey:@"_filename"]];
    [cell.imageView setImageWithURL:[NSURL URLWithString:tmpURL] placeholderImage:[UIImage imageNamed:@"AppIcon"]];
    return cell;
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewRowAction *modifyAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:NSLocalizedString(@"btn_slide_copylink", @"Upload Tab") handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath *indexPath) {
        [UIPasteboard generalPasteboard].string = [[NetworkManager sharedManager] generateLinkForImage:[[[[[NetworkManager sharedManager] imageList] objectForKey:self.gid] objectAtIndex:indexPath.row] objectForKey:@"_filename"]];
    }];
    modifyAction.backgroundColor = [UIColor orangeColor];
    
    UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:NSLocalizedString(@"btn_slide_delete", @"Upload Tab") handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        [[NetworkManager sharedManager] deleteImageWithName:[[[[[NetworkManager sharedManager] imageList] objectForKey:self.gid] objectAtIndex:indexPath.row] objectForKey:@"_filename"] success:^(NSDictionary *responseObject) {
            [[[[NetworkManager sharedManager] imageList] objectForKey:self.gid] removeObjectAtIndex:indexPath.row];
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:YES];
        } failure:^(NSString *failureReason, NSInteger statusCode) {
            [NetworkManager showMessage:failureReason];
        }];
    }];
    return @[modifyAction, deleteAction];
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.detailedViewController.imageID = indexPath.row;
    self.detailedViewController.imageList = [[[NetworkManager sharedManager] imageList] objectForKey:self.gid];
    
    self.detailedViewController.title = NSLocalizedString(@"label_loading", @"Image");
    [self.navigationController pushViewController:self.detailedViewController animated:YES];
}

#pragma mark - More

- (NSString *)bytesToUIString:(NSNumber *) number {
    double size = [number doubleValue];
    unsigned long i = 0;
    while (size >= 1000) {
        size /= 1024;
        i++;
    }
    NSArray *extension = [[NSArray alloc] initWithObjects:@"Byte", @"KB", @"MB", @"GB", @"TB", @"PB", @"EB", @"ZB", @"YB" ,@"???" , nil];

    if(i>([extension count]-2)) i = [extension count]-1;
    return [NSString stringWithFormat:@"%.1f %@", size, [extension objectAtIndex:i]];
}

- (void) doCopyLinks {
    NSMutableString* linkX = [[NSMutableString alloc] init];
    unsigned long i;
    for(i = 0;i < [[[[NetworkManager sharedManager] imageList] objectForKey:self.gid] count];i++) {
        [linkX appendString:[[NetworkManager sharedManager] generateLinkForImage:[[[[[NetworkManager sharedManager] imageList] objectForKey:self.gid] objectAtIndex:i] objectForKey:@"_filename"]]];
    }
    [UIPasteboard generalPasteboard].string = linkX;
    [NetworkManager showMessage:[NSString stringWithFormat:NSLocalizedString(@"msg_copylink_done %ld", @"Upload Tab"), i]];
}



@end
