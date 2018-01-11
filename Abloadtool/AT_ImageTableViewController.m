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
    //self.navigationItem.title = NSLocalizedString(@"Images", @"Navigation Title");
    //self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(doAddGallery:)];
    
    // Init TableView
    [self.tableView registerClass:[AT_ImageTableViewCell class] forCellReuseIdentifier:cImageCell];
    //self.clearsSelectionOnViewWillAppear = NO;

    self.detailedViewController = [[AT_DetailedViewController alloc] init];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void) viewWillAppear:(BOOL)animated {
    //NSLog(@"image Table: - gid: %@", self.gid);
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //NSLog(@"image Table: %ld", [[[[NetworkManager sharedManager] imageList] objectForKey:self.gid] count]);
    return [[[[NetworkManager sharedManager] imageList] objectForKey:self.gid] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cImageCell forIndexPath:indexPath];
    cell.separatorInset = UIEdgeInsetsZero;

    cell.textLabel.text = [[[[[NetworkManager sharedManager] imageList] objectForKey:self.gid] objectAtIndex:indexPath.row] objectForKey:@"_filename"];
    cell.detailTextLabel.text = [self bytesToUIString:[[[[[NetworkManager sharedManager] imageList] objectForKey:self.gid] objectAtIndex:indexPath.row] objectForKey:@"_filesize"]];

    NSString *tmpURL = [NSString stringWithFormat:@"%@/mini/%@", cURL_BASE, [[[[[NetworkManager sharedManager] imageList] objectForKey:self.gid] objectAtIndex:indexPath.row] objectForKey:@"_filename"]];
    [cell.imageView setImageWithURL:[NSURL URLWithString:tmpURL] placeholderImage:[UIImage imageNamed:@"AppIcon"]];
    return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.detailedViewController.imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/img/%@", cURL_BASE, [[[[[NetworkManager sharedManager] imageList] objectForKey:self.gid] objectAtIndex:indexPath.row] objectForKey:@"_filename"]]];
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
    NSArray *extension = [[NSArray alloc] initWithObjects:@"Byte", @"KiB", @"MiB", @"GiB", @"TiB", @"PiB", @"EiB", @"ZiB", @"YiB" ,@"???" , nil];
    
    if(i>([extension count]-2)) i = [extension count]-1;
    return [NSString stringWithFormat:@"%.1f %@", size, [extension objectAtIndex:i]];
}


@end
