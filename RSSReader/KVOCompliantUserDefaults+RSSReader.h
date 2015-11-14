//
//  KVOCompliantUserDefaults+RSSReader.h
//  RSSReader
//
//  Created by Grigory Entin on 25.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

#import <GEBase/KVOCompliantUserDefaults.h>

@interface KVOCompliantUserDefaults (RSSReader)

@property (nonatomic) BOOL traceEnabled;
@property (nonatomic) BOOL traceLabelsEnabled;
@property (nonatomic) BOOL showUnreadOnly;
@property (copy, nonatomic) NSString *authToken;
@property (copy, nonatomic) NSString *login;
@property (copy, nonatomic) NSString *password;
@property (nonatomic) BOOL analyticsEnabled;
@property (nonatomic) BOOL stateRestorationDisabled;
@property (nonatomic) BOOL fetchResultsAreAnimated;
@property (nonatomic) BOOL batchSavingDisabled;
@property (nonatomic) BOOL itemsAreSortedByLoadDate;
@property (nonatomic) NSDate *foldersLastUpdateDate;
@property (nonatomic) NSData *foldersLastUpdateErrorEncoded;
@property (nonatomic) BOOL pageViewsEnabled;

@end
