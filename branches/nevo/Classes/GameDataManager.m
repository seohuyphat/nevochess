/***************************************************************************
 *  Copyright 2009-2010 Nevo Hua  <nevo.hua@playxiangqi.com>               *
 *                                                                         * 
 *  This file is part of NevoChess.                                        *
 *                                                                         *
 *  NevoChess is free software: you can redistribute it and/or modify      *
 *  it under the terms of the GNU General Public License as published by   *
 *  the Free Software Foundation, either version 3 of the License, or      *
 *  (at your option) any later version.                                    *
 *                                                                         *
 *  NevoChess is distributed in the hope that it will be useful,           *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of         *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the          *
 *  GNU General Public License for more details.                           *
 *                                                                         *
 *  You should have received a copy of the GNU General Public License      *
 *  along with NevoChess.  If not, see <http://www.gnu.org/licenses/>.     *
 ***************************************************************************/

//
// Part of the code in this file is from file "CoreDataBooksAppDelegates.m" in iPhone sample "CoreDataBooks"
//

#import "GameDataManager.h"

// the singleton game data manager
static GameDataManager *gameDataManager;

@implementation GameDataManager
- (id)init
{
    self = [super init];
    return self;
}

- (void)dealloc
{
    [managedObjectModel release];
    [managedObjectContext release];
    [persistentStoreCoordinator release];
    [super dealloc];
}

#pragma mark Core Data
//
// Returns the path to the application's documents directory.
// We need to write to Application Document dir since that's the only place allowing us to write into
//
- (NSString *)applicationDocumentsDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

//
// Returns the persistent store coordinator for the application.
// Persistent store coordinator is the layer between data store and application
// If the coordinator doesn't already exist, it is created and a data store is added to it.
//
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }
  
  
    NSString *storePath = [[self applicationDocumentsDirectory] stringByAppendingPathComponent: @"game.sqlite"];
    //
    // Set up the store.
    // For the sake of illustration, provide a pre-populated default store.
    //
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // If the expected store doesn't exist, copy the default store.
    if (![fileManager fileExistsAtPath:storePath]) {
        NSString *defaultStorePath = [[NSBundle mainBundle] pathForResource:@"game" ofType:@"sqlite"];
        if (defaultStorePath) {
            [fileManager copyItemAtPath:defaultStorePath toPath:storePath error:NULL];
        }
    }
    
    NSURL *storeUrl = [NSURL fileURLWithPath:storePath];
	
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, 
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];	
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
    
    NSError *error;
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:options error:&error]) {
        // Update to handle the error appropriately.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        exit(-1);  // Fail
    }
	
    return persistentStoreCoordinator;
}

//
// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
//
- (NSManagedObjectContext *) managedObjectContext {
	
    if (managedObjectContext != nil) {
        return managedObjectContext;
    }
	
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    return managedObjectContext;
}


//
// Returns the managed object model for the application.
// If the model doesn't already exist, it is created by merging all of the models found in the application bundle.
//
- (NSManagedObjectModel *)managedObjectModel {
	
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
    // this will load model from main bundle
    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];    
    return managedObjectModel;
}

//
// load array of fetched results for specific entity
// return nil or NSArray object, and optionally return error info.
//
- (NSArray*)loadEntityForName:(NSString*)name 
              searchPredicate:(NSPredicate*)predicate 
                         sort:(NSSortDescriptor*)sort 
                        error:(NSError**)error
{
    NSEntityDescription *entityDescription = [NSEntityDescription
                                              entityForName:name inManagedObjectContext:[self managedObjectContext]];
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    [request setEntity:entityDescription];
    
    if (predicate) [request setPredicate:predicate];
    if (sort) [request setSortDescriptors:[NSArray arrayWithObject:sort]];
    
    NSArray *result = [[self managedObjectContext] executeFetchRequest:request error:error];
    return result;
}

//
// poll the managedObjectContext to see if it contains the specific objects
//
- (BOOL)hasEntityForName:(NSString*)name 
         searchPredicate:(NSPredicate*)predicate 
                    sort:(NSSortDescriptor*)sort 
                   error:(NSError**)error
{
    NSEntityDescription *entityDescription = [NSEntityDescription
                                              entityForName:name inManagedObjectContext:[self managedObjectContext]];
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    [request setEntity:entityDescription];
    
    if (predicate) [request setPredicate:predicate];
    if (sort) [request setSortDescriptors:[NSArray arrayWithObject:sort]];
    
    NSArray *result = [[self managedObjectContext] executeFetchRequest:request error:error];
    return ([result count] > 0 ? YES : NO);
}

//
// prepare and add a new entity object into underlying managed object model;
// any change toward the returned object would be automatically reflected into the object store
//
- (NSManagedObject*)prepareAndAddEntityForName:(NSString*)name
{
    return [NSEntityDescription insertNewObjectForEntityForName:name inManagedObjectContext:[self managedObjectContext]];
}

#pragma mark return game data manager handle 
//
// return singleton game data manager
//
+ (DataManager*)getDataManager
{
    if(gameDataManager == nil)
        gameDataManager = [[GameDataManager alloc] init];
    return gameDataManager;
}

@end

__attribute__ ((__destructor__))
static void  destroyMyselfOnQuit() 
{
    [gameDataManager release];
}
