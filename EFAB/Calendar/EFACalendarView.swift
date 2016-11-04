//
//  EFACalendarView.swift
//  EFAB
//
//  Created by Lucas Lell on 11/3/16.
//  Copyright © 2016 Luuke192. All rights reserved.
//

import UIKit
import AFDateHelper

// Step 18: Create class and protocols
let numberOfDaysInWeek = 7
let maximumNumberOfRows = 6
let headerDefaultHeight: CGFloat = 60.0
let monthsInYear = 12

// Step 19: create protocol
protocol EFACalendarViewDelegate {
    func calendar(_ calendar: EFACalendarView, didSelectDate date: Date) -> Void
}

class EFACalendarView: UIView {
    // Step 19: delegate var
    var delegate: EFACalendarViewDelegate?
    
    let startDate = Utils.adjustedTime().dateBySubtractingMonths(monthsInYear * 2)
    let endDate = Utils.adjustedTime().dateByAddingMonths(monthsInYear * 2)
    
    fileprivate var calendarStartDate: Date = Date()
    fileprivate var todayIndexPath: IndexPath?
    fileprivate var dateBeingSelectedByUser: Date?
    
    // Step 18: add additional vars (explain set and lazy)
    // private(set) means it's publicly readable but privately writable
    fileprivate(set) var selectedIndexPath: IndexPath?
    
    //
    var monthInfo: [Int: (firstDay: Int, numberOfDays: Int)] = [:]
    
    // lazy means that the initial value is not set until the first time it is used.  Useful when the
    // value is dependent on outside factors whose values are not konwn until after initialization is complete
    lazy var layout: EFACalendarFlowLayout = {
        $0.scrollDirection = UICollectionViewScrollDirection.horizontal
        $0.minimumInteritemSpacing = 0
        $0.minimumLineSpacing = 0
        $0.scrollDirection = .horizontal
        return $0
    }(EFACalendarFlowLayout())
    
    lazy var collectionView: UICollectionView = {
        $0.dataSource = self
        $0.delegate = self
        $0.isPagingEnabled = true
        $0.backgroundColor = UIColor.clear
        $0.showsHorizontalScrollIndicator = false
        $0.showsVerticalScrollIndicator = false
        $0.allowsMultipleSelection = false
        return $0
    }(UICollectionView(frame: CGRect.zero, collectionViewLayout: self.layout))
    
    lazy var headerView: EFACalendarHeaderView = {
        return Bundle.main.loadNibNamed("EFACalendarHeaderView", owner: self, options: nil)!.first as! EFACalendarHeaderView
    }()
    
    override var frame: CGRect {
        didSet {
            let height = frame.size.height - headerDefaultHeight
            let width = frame.size.width
            
            headerView.frame = CGRect(x:0.0, y:0.0, width: frame.size.width, height:headerDefaultHeight)
            collectionView.frame = CGRect(x:0.0, y:headerDefaultHeight, width: width, height: height)
            
            let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
            layout.itemSize = CGSize(width: width / CGFloat(numberOfDaysInWeek), height: height / CGFloat(maximumNumberOfRows))
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // Step 18: add awakeFromNib and selectDate
    override func awakeFromNib() {
        clipsToBounds = true
        collectionView.register(UINib(nibName: "EFACalendarDayCell", bundle: nil), forCellWithReuseIdentifier: String(describing: EFACalendarDayCell.self))
        addSubview(headerView)
        addSubview(collectionView)
    }
    
    
    // MARK: - Public functions
    func selectDate(_ date: Date) {
        let monthNum = date.month() - calendarStartDate.month() + monthsInYear * (date.year() - calendarStartDate.year());
        let dayNum = date.day() + date.dateAtTheStartOfMonth().weekday() - 2 // Subtract 1 for day starting at 1 instead of zero, subtract 1 for sunday == 1
        let indexPath = IndexPath(item: dayNum, section: monthNum)
        
        collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
        
        selectedIndexPath = indexPath
    }
}


// MARK: - UICollectionViewDataSource/Delegate
extension EFACalendarView: UICollectionViewDataSource, UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        calendarStartDate = startDate.dateAtTheStartOfMonth()
        
        let today = Date()
        
        if calendarStartDate.isInPast() && endDate.isInFuture() {
            let monthNum = today.month() - calendarStartDate.month() + monthsInYear * (today.year() - calendarStartDate.year());
            let dayNum = today.day() - 1
            todayIndexPath = IndexPath(item: dayNum, section: monthNum)
        }
        
        return monthsInYear * (endDate.year() - startDate.year())
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let currentMonth = calendarStartDate.dateByAddingMonths(section)
        monthInfo[section] = (currentMonth.dateAtTheStartOfMonth().weekday() - 1, currentMonth.monthDays())
        return numberOfDaysInWeek * maximumNumberOfRows
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let dayCell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: EFACalendarDayCell.self), for: indexPath) as! EFACalendarDayCell
        
        let currentMonthInfo = monthInfo[(indexPath as NSIndexPath).section]!
        let firstDay = currentMonthInfo.firstDay
        let numDays = currentMonthInfo.numberOfDays
        
        let fromStartOfMonthIndexPath = IndexPath(item: (indexPath as NSIndexPath).item - firstDay, section: (indexPath as NSIndexPath).section)
        
        if (indexPath as NSIndexPath).item >= firstDay && (indexPath as NSIndexPath).item < firstDay + numDays {
            dayCell.textLabel.text = String((fromStartOfMonthIndexPath as NSIndexPath).item + 1)
            dayCell.isHidden = false
        } else {
            dayCell.textLabel.text = ""
            dayCell.isHidden = true
        }
        
        dayCell.isSelected = selectedIndexPath == indexPath
        
        if (indexPath as NSIndexPath).section == 0 && (indexPath as NSIndexPath).item == 0 {
            scrollViewDidEndDecelerating(collectionView)
        }
        
        if let index = todayIndexPath {
            dayCell.isToday = ((index as NSIndexPath).section == (indexPath as NSIndexPath).section && (index as NSIndexPath).item + firstDay == (indexPath as NSIndexPath).item)
        }
        
        // Step 19: check for expenses
        let date = startDate.dateByAddingMonths(indexPath.section)
            .dateAtTheStartOfMonth().dateByAddingDays(indexPath.item)
            .dateBySubtractingDays(firstDay)
        dayCell.hasExpenses = UserStore.shared.monthExpenses[date.year()]?[date.month()]?[date.day()] != nil
        
        return dayCell
    }
    
    // Step 19: didSelectItemAtIndexPath
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath != selectedIndexPath {
            selectedIndexPath = indexPath
            let currentMonthInfo = monthInfo[(indexPath as NSIndexPath).section]!
            let firstDayInMonth = currentMonthInfo.firstDay
            let date = calendarStartDate.dateByAddingMonths(indexPath.section).dateByAddingDays(indexPath.item - firstDayInMonth)
            
            delegate?.calendar(self, didSelectDate: date)
        }
    }
}


// MARK: - UIScrollViewDelegate
// Step 18: UIScrollViewDelegate
extension EFACalendarView: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        calculateDateBasedOnScrollViewPosition(scrollView)
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        calculateDateBasedOnScrollViewPosition(scrollView)
    }
    
    func calculateDateBasedOnScrollViewPosition(_ scrollView: UIScrollView) {
        var page = Int(floor(collectionView.contentOffset.x / collectionView.bounds.size.width))
        page = max(page, 0)
        
        var monthsOffsetComponents = DateComponents()
        monthsOffsetComponents.month = page
        
        let displayDate = calendarStartDate.dateByAddingMonths(page)
        headerView.monthLabel.text = "\(displayDate.monthToString()) \(displayDate.year())"
        
        // Step 19: Call getExpenses
        UserStore.shared.getExpenses(displayDate.month(), year: displayDate.year())
    }
}
