//
//  MNCalendarView.m
//  MNCalendarView
//
//  Created by Min Kim on 7/23/13.
//  Copyright (c) 2013 min. All rights reserved.
//

#import "MNCalendarView.h"
#import "MNCalendarViewLayout.h"
#import "MNCalendarViewDayCell.h"
#import "MNCalendarViewWeekdayCell.h"
#import "MNCalendarHeaderView.h"
#import "MNFastDateEnumeration.h"
#import "NSDate+MNAdditions.h"

@interface MNCalendarView() <UICollectionViewDataSource, UICollectionViewDelegate>

@property(nonatomic,strong,readwrite) UICollectionView *collectionView;
@property(nonatomic,strong,readwrite) UICollectionViewFlowLayout *layout;

@property(nonatomic,strong,readwrite) NSArray *monthDates;
@property(nonatomic,strong,readwrite) NSArray *weekdaySymbols;
@property(nonatomic,assign,readwrite) NSUInteger daysInWeek;

@property(nonatomic,strong,readwrite) NSDateFormatter *monthFormatter;

- (NSDate *)firstVisibleDateOfMonth:(NSDate *)date;
- (NSDate *)lastVisibleDateOfMonth:(NSDate *)date;

- (BOOL)dateEnabled:(NSDate *)date;
- (BOOL)canSelectItemAtIndexPath:(NSIndexPath *)indexPath;

- (void)applyConstraints;

@end

@implementation MNCalendarView

- (void)commonInit {
  self.calendar   = NSCalendar.currentCalendar;
  self.fromDate   = [NSDate.date mn_beginningOfDay:self.calendar];
  self.toDate     = [self.fromDate dateByAddingTimeInterval:MN_YEAR * 4];
  self.selectedDates = [[NSMutableSet alloc] init];
  self.daysInWeek = 7;
  self.isReadOnly = NO;
  
  self.headerViewClass  = MNCalendarHeaderView.class;
  self.weekdayCellClass = MNCalendarViewWeekdayCell.class;
  self.dayCellClass     = MNCalendarViewDayCell.class;
  
  _separatorColor = [UIColor colorWithRed:.85f green:.85f blue:.85f alpha:1.f];
  
  [self addSubview:self.collectionView];
  [self applyConstraints];
  [self reloadData];
}

- (id)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    [self commonInit];
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder: aDecoder];
  if ( self ) {
    [self commonInit];
  }
  
  return self;
}

- (UICollectionView *)collectionView {
  if (nil == _collectionView) {
    MNCalendarViewLayout *layout = [[MNCalendarViewLayout alloc] init];

    _collectionView =
      [[UICollectionView alloc] initWithFrame:CGRectZero
                         collectionViewLayout:layout];
    _collectionView.backgroundColor = [UIColor colorWithRed:.96f green:.96f blue:.96f alpha:1.f];
    _collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    _collectionView.showsHorizontalScrollIndicator = NO;
    _collectionView.showsVerticalScrollIndicator = NO;
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    
    [self registerUICollectionViewClasses];
  }
  return _collectionView;
}

- (void)setSeparatorColor:(UIColor *)separatorColor {
  _separatorColor = separatorColor;
}

- (void)setCalendar:(NSCalendar *)calendar {
  _calendar = calendar;
  
  self.monthFormatter = [[NSDateFormatter alloc] init];
  self.monthFormatter.calendar = calendar;
  [self.monthFormatter setDateFormat:@"MMMM yyyy"];
}

- (void)setSelectedDate:(NSDate *)selectedDate {
  _selectedDate = [selectedDate mn_beginningOfDay:self.calendar];
}

- (void)setSelectedDates:(NSMutableSet *)selectedDates{
  NSMutableSet *newSet = [NSMutableSet set];
  for (NSDate *date in selectedDates) {
    [newSet addObject:[date mn_beginningOfDay:self.calendar]];
  }
  _selectedDates = newSet;
}

- (void)reloadData {
  NSMutableArray *monthDates = @[].mutableCopy;
  MNFastDateEnumeration *enumeration =
    [[MNFastDateEnumeration alloc] initWithFromDate:[self.fromDate mn_firstDateOfMonth:self.calendar]
                                             toDate:[self.toDate mn_firstDateOfMonth:self.calendar]
                                           calendar:self.calendar
                                               unit:NSMonthCalendarUnit];
  for (NSDate *date in enumeration) {
    [monthDates addObject:date];
  }
  self.monthDates = monthDates;
  
  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  formatter.calendar = self.calendar;
  
  self.weekdaySymbols = formatter.shortWeekdaySymbols;
  
  [self.collectionView reloadData];
}

- (void)registerUICollectionViewClasses {
  [_collectionView registerClass:self.dayCellClass
      forCellWithReuseIdentifier:MNCalendarViewDayCellIdentifier];
  
  [_collectionView registerClass:self.weekdayCellClass
      forCellWithReuseIdentifier:MNCalendarViewWeekdayCellIdentifier];
  
  [_collectionView registerClass:self.headerViewClass
      forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
             withReuseIdentifier:MNCalendarHeaderViewIdentifier];
}

- (NSDate *)firstVisibleDateOfMonth:(NSDate *)date {
  date = [date mn_firstDateOfMonth:self.calendar];
  
  NSDateComponents *components =
    [self.calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit|NSWeekdayCalendarUnit
                fromDate:date];
  
  return
    [[date mn_dateWithDay:-((components.weekday - 1) % self.daysInWeek) calendar:self.calendar] dateByAddingTimeInterval:MN_DAY];
}

- (NSDate *)lastVisibleDateOfMonth:(NSDate *)date {
  date = [date mn_lastDateOfMonth:self.calendar];
  
  NSDateComponents *components =
    [self.calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit|NSWeekdayCalendarUnit
                     fromDate:date];
  
  return
    [date mn_dateWithDay:components.day + (self.daysInWeek - 1) - ((components.weekday - 1) % self.daysInWeek)
                calendar:self.calendar];
}

- (void)applyConstraints {
  NSDictionary *views = @{@"collectionView" : self.collectionView};
  [self addConstraints:
   [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[collectionView]|"
                                           options:0
                                           metrics:nil
                                             views:views]];
  
  [self addConstraints:
   [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[collectionView]|"
                                           options:0
                                           metrics:nil
                                             views:views]
   ];
}

- (BOOL)dateIsVisibility:(NSDate *)date monthDate:(NSDate *)monthDate {
  NSDateComponents *dateComponents =
  [self.calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit
                   fromDate:date];
  NSDateComponents *monthComponents =
  [self.calendar components:NSMonthCalendarUnit
                   fromDate:monthDate];
  NSInteger targetMonth = [dateComponents month];
  NSInteger month = [monthComponents month];
  if (targetMonth == month) {
    return YES;
  }
  return NO;
}

- (BOOL)dateEnabled:(NSDate *)date {
  if (self.delegate && [self.delegate respondsToSelector:@selector(calendarView:shouldSelectDate:)]) {
    return [self.delegate calendarView:self shouldSelectDate:date];
  }
  return YES;
}

- (BOOL)canSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  MNCalendarViewCell *cell = (MNCalendarViewCell *)[self collectionView:self.collectionView cellForItemAtIndexPath:indexPath];

  BOOL enabled = cell.enabled;

  if ([cell isKindOfClass:MNCalendarViewDayCell.class] && enabled) {
    MNCalendarViewDayCell *dayCell = (MNCalendarViewDayCell *)cell;

    enabled = [self dateEnabled:dayCell.date];
  }

  return enabled;
}

- (NSIndexPath *)indexPathForDate:(NSDate *)date
{
    if ([date compare:_fromDate] == NSOrderedAscending || [date compare:_toDate] == NSOrderedDescending) {
        return nil;
    }
    NSDateComponents *toDateComp      = [self.calendar components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:date];
    NSDateComponents *initialDateComp = [self.calendar components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:_fromDate];
    
    NSInteger yearDiff  = [toDateComp year] - [initialDateComp year];
    NSInteger monthDiff = fabs([toDateComp month] - [initialDateComp month]);
    NSInteger dayDiff   = [toDateComp day];
    
    [toDateComp setDay:1];
    toDateComp = [self.calendar components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit|NSWeekdayCalendarUnit) fromDate:[self.calendar dateFromComponents:toDateComp]];
    
    NSInteger section = (yearDiff * 12) + monthDiff;
    NSInteger row = [toDateComp weekday] - 1 + dayDiff - 1 + self.daysInWeek;
    
    return [NSIndexPath indexPathForItem:row inSection:section];
}

/*
 Should be called at - (void)viewDidLayoutSubviews
 if you want to scroll at the begining.
 */
- (void)scrollToDate:(NSDate *)date animated:(BOOL)animated
{
    NSIndexPath *indexPath = [self indexPathForDate:date];
    if (!indexPath) {
        return;
    }
    [self.collectionView scrollToItemAtIndexPath:indexPath
                                atScrollPosition:UICollectionViewScrollPositionCenteredVertically
                                        animated:animated];
}

/*
 Should be called at - (void)viewDidLayoutSubviews
 if you want to scroll at the begining.
 */
- (void)scrollToDate:(NSDate *)date
{
    [self scrollToDate:date animated:YES];
}

/*
 Should be called at - (void)viewDidLayoutSubviews
 if you want to scroll at the begining.
 */
- (void)selectDate:(NSDate *)date animated:(BOOL)animated
{
    NSIndexPath *indexPath = [self indexPathForDate:date];
    if (!indexPath) {
        return;
    }
    [self.collectionView selectItemAtIndexPath:indexPath
                                      animated:animated
                                scrollPosition:UICollectionViewScrollPositionCenteredVertically];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
  return self.monthDates.count;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath {
  MNCalendarHeaderView *headerView =
    [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                       withReuseIdentifier:MNCalendarHeaderViewIdentifier
                                              forIndexPath:indexPath];

  headerView.backgroundColor = self.collectionView.backgroundColor;
  headerView.titleLabel.text = [self.monthFormatter stringFromDate:self.monthDates[indexPath.section]];

  return headerView;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  NSDate *monthDate = self.monthDates[section];
  
  NSDateComponents *components =
    [self.calendar components:NSDayCalendarUnit
                     fromDate:[self firstVisibleDateOfMonth:monthDate]
                       toDate:[self lastVisibleDateOfMonth:monthDate]
                      options:0];
  
  return self.daysInWeek + components.day + 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {

  if (indexPath.item < self.daysInWeek) {
    MNCalendarViewWeekdayCell *cell =
      [collectionView dequeueReusableCellWithReuseIdentifier:MNCalendarViewWeekdayCellIdentifier
                                                forIndexPath:indexPath];
    
    cell.backgroundColor = self.collectionView.backgroundColor;
    cell.titleLabel.text = self.weekdaySymbols[indexPath.item];
    cell.separatorColor = self.separatorColor;
    return cell;
  }
  MNCalendarViewDayCell *cell =
    [collectionView dequeueReusableCellWithReuseIdentifier:MNCalendarViewDayCellIdentifier
                                              forIndexPath:indexPath];
  cell.separatorColor = self.separatorColor;
  
  NSDate *monthDate = self.monthDates[indexPath.section];
  NSDate *firstDateInMonth = [self firstVisibleDateOfMonth:monthDate];

  NSUInteger day = indexPath.item - self.daysInWeek;
  
  NSDateComponents *components =
    [self.calendar components:NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit
                     fromDate:firstDateInMonth];
  components.day += day;
  
  NSDate *date = [self.calendar dateFromComponents:components];
  [cell setDate:date
          month:monthDate
       calendar:self.calendar];
  
  if (_hiddenTodayIndicator == NO) {
    NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:date];
    if (0 < interval && interval < MN_DAY) {
      NSDictionary *stringAttributes = @{NSUnderlineStyleAttributeName: [NSNumber numberWithBool:YES]};
      NSAttributedString *decoratedString = [[NSAttributedString alloc] initWithString:cell.titleLabel.text
                                                                            attributes:stringAttributes];
      cell.titleLabel.attributedText = decoratedString;
    }
  }

  if (cell.enabled) {
    [cell setEnabled:[self dateEnabled:date]];
  }

  if (self.displaysDaysOfOtherMonths) {
    if ([self dateIsVisibility:date monthDate:monthDate]) {
      [cell setVisible:YES];
    } else {
      [cell setVisible:NO];
    }
  }

  if (_shouldMultipleSelect && self.selectedDates && cell.enabled) {
    [cell setSelected:[_selectedDates containsObject:cell.date]];
  } else if (_selectedDate && cell.enabled) {
    [cell setSelected:[date isEqualToDate:self.selectedDate]];
  }
    
    if (_isReadOnly) {
        cell.userInteractionEnabled = NO;
    }
  
  return cell;
}

#pragma mark - UICollectionViewDelegate

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
  return [self canSelectItemAtIndexPath:indexPath];
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  return [self canSelectItemAtIndexPath:indexPath];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  MNCalendarViewCell *cell = (MNCalendarViewCell *)[self collectionView:collectionView cellForItemAtIndexPath:indexPath];

  if ([cell isKindOfClass:MNCalendarViewDayCell.class] && cell.enabled) {
    MNCalendarViewDayCell *dayCell = (MNCalendarViewDayCell *)cell;
    
    if (_shouldMultipleSelect) {
      if ([self.selectedDates containsObject:dayCell.date]) {
        [self.selectedDates removeObject:dayCell.date];
      } else {
        [self.selectedDates addObject:dayCell.date];
      }
    }
    self.selectedDate = dayCell.date;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(calendarView:didSelectDate:)]) {
      [self.delegate calendarView:self didSelectDate:dayCell.date];
    }
    
    [self.collectionView reloadData];
  }
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
  
  CGFloat width      = self.bounds.size.width;
  CGFloat itemWidth  = roundf(width / self.daysInWeek);
  CGFloat itemHeight = indexPath.item < self.daysInWeek ? 30.f : itemWidth;
  
  NSUInteger weekday = indexPath.item % self.daysInWeek;
  
  if (weekday == self.daysInWeek - 1) {
    itemWidth = width - (itemWidth * (self.daysInWeek - 1));
  }
  
  return CGSizeMake(itemWidth, itemHeight);
}

@end
