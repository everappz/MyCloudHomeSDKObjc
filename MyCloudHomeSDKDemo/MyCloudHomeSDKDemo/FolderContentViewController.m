//
//  FolderContentViewController.m
//  MyCloudHomeSDKDemo
//
//  Created by Artem on 08.06.2020.
//  Copyright © 2020 Everappz. All rights reserved.
//

#import "FolderContentViewController.h"
#import "MyCloudHomeHelper.h"
#import "LSOnlineFile.h"
#import <MyCloudHomeSDKObjc/MyCloudHomeSDKObjc.h>


NSString * const kTableViewCellIdentifier = @"kTableViewCellIdentifier";

@interface FolderContentViewController ()

@property (nonatomic,strong)id<MCHAPIClientCancellableRequest> request;

@property (nonatomic,strong)NSArray <LSOnlineFile *> *files;

@end

@implementation FolderContentViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    self.tableView.rowHeight = 52.0;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.title = self.rootDirectory.name;
    [self reloadContentDataAndUpdateView];
}

- (void)reloadContentDataAndUpdateView{
    if (self.userID == nil) {
        __weak typeof (self) weakSelf = self;
        [self loadUserIDWithCompletion:^(NSString *userID, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error){
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                                   message:error.localizedDescription
                                                                            preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                              style:UIAlertActionStyleCancel
                                                            handler:nil]];
                    [weakSelf presentViewController:alert
                                           animated:YES
                                         completion:nil];
                    [weakSelf.tableView reloadData];
                }
                else{
                    [weakSelf reloadContentDataAndUpdateViewInternal];
                }
            });
        }];
    }
    else{
        [self reloadContentDataAndUpdateViewInternal];
    }
}

- (void)reloadContentDataAndUpdateViewInternal{
    __weak typeof (self) weakSelf = self;
    void(^completion)(NSArray<LSOnlineFile *> *, NSError *) = ^(NSArray<LSOnlineFile *> *files, NSError *error){
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error){
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                               message:error.localizedDescription
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                          style:UIAlertActionStyleCancel
                                                        handler:nil]];
                [weakSelf presentViewController:alert
                                       animated:YES
                                     completion:nil];
            }
            weakSelf.files = files;
            [weakSelf.tableView reloadData];
        });
    };
    
    NSParameterAssert(self.userID!=nil);
    if(self.rootDirectory == nil){
        [self loadDevicesForUserID:self.userID completion:completion];
    }
    else{
        [self loadFolderContent:self.rootDirectory completion:completion];
    }
}

- (void)loadFolderContent:(LSOnlineFile *)directory
               completion:(void(^)(NSArray<LSOnlineFile *> *files,NSError *error))completion{
    NSString *itemID = self.rootDirectory.modelID;
    NSURL *deviceURL = self.rootDirectory.deviceURL;
    NSString *deviceID = self.rootDirectory.deviceID;
    NSParameterAssert(itemID);
    NSParameterAssert(deviceURL);
    if(itemID==nil || deviceURL==nil){
        NSParameterAssert(NO);
        if(completion){
            completion(nil,[MyCloudHomeHelper unknownError]);
        }
        return;
    }
    if([deviceID isEqualToString:itemID]){
        itemID = kMCHFolderIDRoot;
    }
    __weak typeof (self) weakSelf = self;
    self.request = [self.client getFilesForDeviceWithURL:deviceURL
                                                parentID:itemID
                                          completionBlock:^(NSArray<NSDictionary *> * _Nullable array, NSError * _Nullable error) {
        if(error){
            if(completion){
                completion(nil,error);
            }
        }
        else if(array!=nil && [array isKindOfClass:[NSArray class]]==NO){
            if(completion){
                completion(nil,[MyCloudHomeHelper unknownError]);
            }
        }
        else{
            NSMutableArray *files = [NSMutableArray new];
            [array enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                MCHFile *file = [[MCHFile alloc] initWithDictionary:obj];
                if(file){
                    [files addObject:file];
                }
            }];
            LSOnlineFile *parentDirectory = weakSelf.rootDirectory;
            NSArray<LSOnlineFile *> *resultFiles = [MyCloudHomeHelper onlineFilesFromApiFiles:files
                                                                              parentDirectory:parentDirectory];
            if(completion){
                completion(resultFiles,nil);
            }
        }
    }];
}

- (void)loadUserIDWithCompletion:(void(^)(NSString *userID,NSError *error))completion{
    [self.client getUserInfoWithCompletionBlock:^(NSDictionary * _Nullable userIDInfoDictionary, NSError * _Nullable error) {
        MCHUser *user = [[MCHUser alloc] initWithDictionary:userIDInfoDictionary];
        NSString *userID = [user identifier];
        if (completion) {
            completion (userID, error);
        }
    }];
}

- (void)loadDevicesForUserID:(NSString *)userIdentifier
                  completion:(void(^)(NSArray<LSOnlineFile *> *files,NSError *error))completion{
    self.request = [self.client getDevicesForUserWithID:userIdentifier
                                         completionBlock:^(NSDictionary * _Nullable dictionary, NSError * _Nullable error) {
        NSArray *array = [dictionary objectForKey:kMCHData];
        if(error){
            if(completion){
                completion(nil,error);
            }
        }
        else if([array isKindOfClass:[NSArray class]]==NO){
            if(completion){
                completion(nil,[MyCloudHomeHelper unknownError]);
            }
        }
        else{
            NSMutableArray *files = [NSMutableArray new];
            [array enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                MCHDevice *device = [[MCHDevice alloc] initWithDictionary:obj];
                if(device){
                    [files addObject:device];
                }
            }];
            LSOnlineFile *parentDirectory = [LSOnlineFile new];
            parentDirectory.url = [NSURL fileURLWithPath:@"/"];
            NSArray<LSOnlineFile *> *resultFiles = [MyCloudHomeHelper onlineFilesFromApiFiles:files
                                                                              parentDirectory:parentDirectory];
            if(completion){
                completion(resultFiles,nil);
            }
        }
    }];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.files.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kTableViewCellIdentifier];
    if(cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kTableViewCellIdentifier];
    }
    LSOnlineFile *file = [self.files objectAtIndex:indexPath.row];
    cell.textLabel.text = file.name;
    if(file.directory == NO){
        cell.imageView.image = [UIImage imageNamed:@"file.png"];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@, %@", file.createdAt, [MyCloudHomeHelper readableStringForByteSize:@(file.contentLength)]];
    }
    else{
        cell.imageView.image = [UIImage imageNamed:@"folder.png"];
        cell.detailTextLabel.text = nil;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    LSOnlineFile *file = [self.files objectAtIndex:indexPath.row];
    if(file.directory){
        FolderContentViewController *contentViewController = [FolderContentViewController new];
        contentViewController.client = self.client;
        contentViewController.userID = self.userID;
        contentViewController.rootDirectory = file;
        [self.navigationController pushViewController:contentViewController animated:YES];
    }
}

@end
