//
//  GameDataManager.h
//  NevoChess
//
//  Created by nevo on 10-1-24.
//  Copyright 2010 PlayXiangqi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DataManager.h"

@class NSManagedObjectModel;
@class NSManagedObjectContext;
@class NSPersistentStoreCoordinator;

@interface GameDataManager : DataManager {
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;	    
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
}

@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end
