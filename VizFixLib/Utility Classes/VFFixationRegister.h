//
//  VFFixationRegister.h
//  vizfixCLI
//
//  Created by Yunfeng Zhang on 2/3/10.
//  Copyright 2010 University of Oregon. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class VFVisualAngleConverter;
@class VFFetchHelper;
@class VFFixation;

@interface VFFixationRegister : NSObject {
	NSManagedObjectContext *moc;
	VFVisualAngleConverter *converter;
	NSArray *visualStimuliArray;
	NSDictionary *customAOIs;
	
	VFFetchHelper *fetchHelper;
	
	double autoAOIDOV;
}

@property (retain) NSDictionary * customAOIs;
@property double autoAOIDOV;

- (id)initWithMOC:(NSManagedObjectContext *)anMOC;
- (void)registerFixationToClosestAOI:(VFFixation *)aFixation;
- (void)registerAllFixations;
- (void)useVisualStimuliOfCategoriesAsAOI:(NSArray *)categories;

@end
