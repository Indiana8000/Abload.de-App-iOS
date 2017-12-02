//
//  AT_UploadTableViewController.m
//  Abloadtool
//
//  Created by Andreas Kreisl on 27.10.17.
//  Copyright © 2017 Andreas Kreisl. All rights reserved.
//

#define c_ICELLID @"ImageTableViewCell"

#import "AT_UploadTableViewController.h"

@interface AT_UploadTableViewController ()

@end

@implementation AT_UploadTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = NSLocalizedString(@"Upload", @"Navigation Title");
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"106-sliders"] style:UIBarButtonItemStylePlain target:self action:@selector(showSettings:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"56-cloud"] style:UIBarButtonItemStylePlain target:self action:@selector(startUploadingImages:)];

    [self.tableView registerClass:UITableViewCell.self forCellReuseIdentifier:c_ICELLID];
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
        return 8;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:c_ICELLID forIndexPath:indexPath];
    
    if(indexPath.section == 0) {
        cell.textLabel.text = NSLocalizedString(@"Add Pictures", @"Upload");
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
    } else {
        cell.textLabel.text = @"Picture #?";
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0) {
        
        UIAlertController *sheet;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            sheet = [UIAlertController alertControllerWithTitle:@"Add Picture from"
                                                        message:nil
                                                 preferredStyle:UIAlertControllerStyleActionSheet];
        } else {
            sheet = [UIAlertController alertControllerWithTitle:@"Add Picture from"
                                                        message:nil
                                                 preferredStyle:UIAlertControllerStyleAlert];
        }
        
        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            UIAlertAction *btn1 = [UIAlertAction actionWithTitle:NSLocalizedString(@"Single Camera Picture", @"TBD") style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
                                                             [self showImagePickerWithSource:UIImagePickerControllerSourceTypeCamera repeateAdd:NO];
                                                         }];
            [sheet addAction:btn1];
            
            UIAlertAction *btn2 = [UIAlertAction actionWithTitle:NSLocalizedString(@"Multiple Camera Picture", @"TBD") style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
                                                             [self showImagePickerWithSource:UIImagePickerControllerSourceTypeCamera repeateAdd:YES];
                                                         }];
            [sheet addAction:btn2];
        }
        
        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
            UIAlertAction *btn3 = [UIAlertAction actionWithTitle:NSLocalizedString(@"Single Photo Lybrary", @"TBD") style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
                                                             [self showImagePickerWithSource:UIImagePickerControllerSourceTypePhotoLibrary repeateAdd:NO];
                                                         }];
            [sheet addAction:btn3];
            
            UIAlertAction *btn4 = [UIAlertAction actionWithTitle:NSLocalizedString(@"Multiple Photo Lybrary", @"TBD") style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
                                                             [self showImagePickerWithSource:UIImagePickerControllerSourceTypePhotoLibrary repeateAdd:YES];
                                                         }];
            [sheet addAction:btn4];
        }
        
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"TBD") style:UIAlertActionStyleDestructive
                                                   handler:^(UIAlertAction * action) {
                                                       [tableView reloadData];
                                                   }];
        [sheet addAction:cancel];

        [self presentViewController:sheet animated:YES completion:nil];
    } else {
        // Picture tapped
    }
}

#pragma mark - More

- (void)showSettings:(id) sender {
    if ( self.pageSetting == nil) {
        self.pageSetting = [[AT_SettingTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
        self.navSetting = [[UINavigationController alloc] initWithRootViewController:self.pageSetting];
        self.navSetting.modalPresentationStyle = UIModalPresentationPopover;
    }
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self.navigationController pushViewController:self.pageSetting animated:YES];
    } else {
        [self.navigationController presentViewController:self.navSetting animated:YES completion:nil];
        UIPopoverPresentationController *presentationController =[self.navSetting popoverPresentationController];
        presentationController.barButtonItem = self.navigationItem.leftBarButtonItem;
    }
}


- (void)showImagePickerWithSource:(UIImagePickerControllerSourceType) sourceType repeateAdd:(BOOL) repeat {
    
}

- (void)startUploadingImages {
    
}
@end
