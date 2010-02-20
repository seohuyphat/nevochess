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

#import "SingleSelectionController.h"
#import "QuartzUtils.h"

@implementation SingleSelectionController

@synthesize _delegate;
@synthesize tag=_tag;
@synthesize selectionIndex=_selectionIndex;

- (id) initWithChoices:(NSArray*)choices delegate:(id<SingleSelectionDelegate>)delegate
{
    if (self = [self initWithNibName:@"SingleSelectionView" bundle:nil]) {
        self._delegate = delegate;
        _choices = [[NSMutableArray alloc] initWithArray:choices];
        _selectionIndex = 0;
    }
    return self;
}

- (void) setSelectionIndex:(unsigned int)selection
{
    if (selection < [_choices count]) {
        _selectionIndex = selection;
    }
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithCGColor:GetCGPatternNamed(@"board_320x480.png")];
}

/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}
*/

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_choices count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    NSString* cellId = [NSString stringWithFormat:@"%d", indexPath.row];
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId] autorelease];
    }
    cell.textLabel.text = [_choices objectAtIndex:indexPath.row];
    cell.accessoryType = (indexPath.row == _selectionIndex ? UITableViewCellAccessoryCheckmark
                                                           : UITableViewCellAccessoryNone);

    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath* oldIndexPath = [NSIndexPath indexPathForRow:_selectionIndex inSection:indexPath.section];
    UITableViewCell* oldCell = [tableView cellForRowAtIndexPath:oldIndexPath];
    oldCell.accessoryType = UITableViewCellAccessoryNone;

    UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    _selectionIndex = indexPath.row;

    [_delegate didSelect:self rowAtIndex:_selectionIndex];
}

- (void)dealloc
{
    [_choices release];
    [_delegate release];
    [super dealloc];
}


@end

