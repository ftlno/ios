//
// Copyright (C) Posten Norge AS
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//         http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

// Core Data model entity names
extern NSString *const kDocumentEntityName;

// API keys
extern NSString *const kDocumentDocumentAPIKey;

extern NSString *const kDocumentDocumentsAPIKey;

@class POSAttachment;
@class POSFolder;

@interface POSDocument : NSManagedObject

// Attributes
@property (strong, nonatomic) NSDate *createdAt;
@property (strong, nonatomic) NSString *creatorName;
@property (strong, nonatomic) NSString *deleteUri;
@property (strong, nonatomic) NSString *location;
@property (strong, nonatomic) NSString *updateUri;
@property (nonatomic, retain) NSString *folderUri;

// Relationships
@property (strong, nonatomic) NSOrderedSet *attachments;
@property (strong, nonatomic) POSFolder *folder;

+ (instancetype)documentWithAttributes:(NSDictionary *)attributes inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
+ (instancetype)existingDocumentWithUpdateUri:(NSString *)updateUri inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
+ (void)reconnectDanglingDocumentsInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
+ (void)deleteAllDocumentsInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
+ (NSArray *)allDocumentsInFolderWithName:(NSString *)folderName mailboxDigipostAddress:(NSString *)mailboxDigipostAddress inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
+ (NSString *)stringForDocumentDate:(NSDate *)date;
- (POSAttachment *)mainDocumentAttachment;
- (void)updateWithAttributes:(NSDictionary *)attributes inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

@end

@interface POSDocument (CoreDataGeneratedAccessors)

- (void)addAttachmentsObject:(POSAttachment *)value;
- (void)removeAttachmentsObject:(POSAttachment *)value;

@end
