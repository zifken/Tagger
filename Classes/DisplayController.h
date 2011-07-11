//
//  SettingsSheetController.h
//  SheetFromOtherNib
//
//  Created by grady player on 6/21/11.
//  Copyright 2011 Objectively Better, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DisplayController : NSWindowController {
@private
	IBOutlet NSWindow    *window;
	NSDictionary *albumDetails;
	id vgmdb; // macruby Vgmdb class
	
	NSString  *selectedLanguage;
	
	NSString *album;
	NSString *artist;
	NSString *albumArtist;
	NSNumber *year;
	NSString *genre;
	NSNumber *totalTracks;
	NSNumber *totalDisks;
	
	NSString *composer;
	NSString *performer;
	NSString *products;
	NSString *publisher;
	NSString *notes;
	
}

- (IBAction)cancelSheet:sender;
- (IBAction)confirmSheet:sender;

- (void)setAlbumUrl:(NSString *)url;
- (id)initWithUrl:(NSString*)url
			vgmdb:(id)vgmdbObject;




@end