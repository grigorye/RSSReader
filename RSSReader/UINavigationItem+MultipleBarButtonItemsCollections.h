//
//  UINavigationItem+MultipleBarButtonItemsCollections.h
//  RSSReader
//
//  Created by Grigory Entin on 28.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

#import <UIKit/UINavigationBar.h>

@interface UINavigationItem (MultipleBarButtonItemsCollections)

@property (nonatomic, strong) IBOutletCollection(UIBarButtonItem) NSArray *rightBarButtonItemsCollection;
@property (nonatomic, strong) IBOutletCollection(UIBarButtonItem) NSArray *leftBarButtonItemsCollection;

@end
