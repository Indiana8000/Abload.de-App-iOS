//
//  AT_AboutTableViewController.m
//  Abloadtool
//
//  Created by Andreas Kreisl on 09.02.18.
//  Copyright © 2018 Andreas Kreisl. All rights reserved.
//

#import "AT_AboutTableViewController.h"


@interface AT_AboutTableViewController ()
    @property UIImageView* abloadImage;
    @property UIImageView* bluepawImage;
@end


@implementation AT_AboutTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = NSLocalizedString(@"nav_title_about", @"Navigation");
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"51-power"] style:UIBarButtonItemStylePlain target:self action:@selector(doLogout:)];

    [self.tableView registerClass:UITableViewCell.self forCellReuseIdentifier:@"AboutCell"];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];

    self.abloadImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo_abload"]];
    self.bluepawImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo_bluepaw"]];
    [self initImage:self.abloadImage];
    [self initImage:self.bluepawImage];
}

- (void)initImage:(UIImageView*)img {
    img.layer.shadowColor = [UIColor blackColor].CGColor;
    img.layer.shadowOpacity = 0.70;
    img.layer.shadowRadius = 2.5;
    img.layer.shadowOffset = CGSizeMake(1.0, 2.0);
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 8;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.row == 1 || indexPath.row == 6) return 140;
    return 35;
}

- (NSString*)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return NSLocalizedString(@"label_footer_clickable", @"About");
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AboutCell" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor clearColor];
    cell.separatorInset = UIEdgeInsetsZero;
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.textLabel.numberOfLines = 0;

    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = NSLocalizedString(@"label_abload_slogan", @"About");
            cell.backgroundColor = [UIColor whiteColor];
            break;
        case 1:
            cell.textLabel.text = @"";
            if(![self.abloadImage isDescendantOfView:cell]) {
                [cell addSubview:self.abloadImage];
            }
            self.abloadImage.frame = CGRectMake((cell.bounds.size.width - self.abloadImage.frame.size.width)/2, (cell.bounds.size.height - self.abloadImage.frame.size.height)/2, self.abloadImage.frame.size.width, self.abloadImage.frame.size.height);
            break;
        case 2:
            cell.textLabel.text = NSLocalizedString(@"label_abload_contact", @"About");
            break;
        case 3:
            cell.textLabel.text = NSLocalizedString(@"label_abload_donation", @"About");
            break;
        case 4:
            cell.textLabel.text = @" ";
            break;
        case 5:
            cell.textLabel.text = NSLocalizedString(@"label_bluepaw_slogan", @"About");
            cell.backgroundColor = [UIColor whiteColor];
            break;
        case 6:
            cell.textLabel.text = @"";
            if(![self.bluepawImage isDescendantOfView:cell]) {
                [cell addSubview:self.bluepawImage];
            }
            self.bluepawImage.frame = CGRectMake((cell.bounds.size.width - self.bluepawImage.frame.size.width)/2, (cell.bounds.size.height - self.bluepawImage.frame.size.height)/2, self.bluepawImage.frame.size.width, self.bluepawImage.frame.size.height);
            break;
        case 7:
            cell.textLabel.text = NSLocalizedString(@"label_bluepaw_slogan", @"About");
            NSString* appBuildString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
            cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"label_bluepaw_build %@ %@", @"About"), appBuildString, [[NetworkManager sharedManager] lastServer]];
            break;
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *tmpDict = [[NSDictionary alloc] initWithObjectsAndKeys: @"Abloadtool-for-iOS", @"referer", nil];
    switch (indexPath.row) {
        case 0:
        case 1:
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://abload.de/"] options:tmpDict completionHandler:nil];
            break;
        case 2:
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:NSLocalizedString(@"url_abload_contact", @"About")] options:tmpDict completionHandler:nil];
            break;
        case 3:
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:NSLocalizedString(@"url_abload_donation", @"About")] options:tmpDict completionHandler:nil];
            break;
        case 5:
        case 6:
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.bluepaw.de/"] options:tmpDict completionHandler:nil];
            break;
        default:
            break;
    }
}

- (void)doLogout:(id) sender {
    [[NetworkManager sharedManager] logoutWithCallback:^{
        [NetworkManager showMessage:NSLocalizedString(@"label_logout_successfull", @"About")];
    }];
}


@end
