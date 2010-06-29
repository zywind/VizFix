//
//  VFFetchHelper.h
//  VizFix
//
//  Created by Yunfeng Zhang on 6/18/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class VFSession;
@interface VFFetchHelper : NSObject {
	NSManagedObjectContext *moc;
}

- (id)initWithMOC:(NSManagedObjectContext *)anMOC;
- (VFSession *)session;
- (NSArray *)topLevelProcedures;
- (NSArray *)fetchModelObjectsForName:(NSString *)entityName 
								 from:(NSNumber *)startTime 
								   to:(NSNumber *)endTime;

- (NSArray *)fetchAllObjectsForName:(NSString *)entityName;

@end
