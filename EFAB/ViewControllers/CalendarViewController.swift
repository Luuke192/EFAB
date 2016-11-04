//
//  CalendarViewController.swift
//  EFAB
//
//  Created by Lucas Lell on 11/3/16.
//  Copyright © 2016 Luuke192. All rights reserved.
//

import UIKit
import AFDateHelper

// Step 18: Create class and implement viewDidAppear, viewDidLayoutSubviews
class CalendarViewController: UIViewController {
    @IBOutlet weak var calendarView: EFACalendarView!
    @IBOutlet weak var tableView: UITableView!
    
    // Step 19: Add selectedDate var
    var selectedDate: Date?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Step 19: add delegate, reset current month/year
        calendarView.delegate = self
        UserStore.shared.currentMonth = nil
        UserStore.shared.currentYear = nil
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        selectedDate = Date()
        NotificationCenter.default.addObserver(self, selector: #selector(expensesReceived(_:)), name: NSNotification.Name(rawValue: Constants.newExpensesFound), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.calendarView.selectDate(Date())
        self.calendarView.collectionView.scrollToItem(at: IndexPath(item: 0, section: 24), at: .left, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let width = self.view.frame.size.width - 16.0 * 2
        let height = width + 20.0
        
        //        self.calendarView.frame = CGRect(x: 16.0, y: 64, width: width, height: height)
        // Step 20: Change y value for frame
        self.calendarView.frame = CGRect(x: 16.0, y: 0, width: width, height: height)
        
        self.calendarView.calculateDateBasedOnScrollViewPosition(self.calendarView.collectionView)
    }
    
    func expensesReceived(_ notification: Notification) {
        self.calendarView.collectionView.reloadData()
        self.tableView.reloadData()
    }
}


// Step 19: Add EFACalendarViewDelegate extension
extension CalendarViewController: EFACalendarViewDelegate {
    func calendar(_ calendar: EFACalendarView, didSelectDate date : Date) {
        selectedDate = date
        tableView.reloadData()
    }
}


// Step 19: UITableViewDelegate/Datasource
extension CalendarViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let selectedDate = selectedDate {
            return UserStore.shared.monthExpenses[selectedDate.year()]?[selectedDate.month()]?[selectedDate.day()]?.count ?? 0
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ExpenseCell")
        
        if let selectedDate = selectedDate,
            let expenses = UserStore.shared.monthExpenses[selectedDate.year()]?[selectedDate.month()]?[selectedDate.day()] {
            let expense = expenses[indexPath.row]
            
            if let amount = expense.amount {
                cell!.textLabel?.text = "\(String(format: "$%.2f", amount)) \(expense.note! != "" ? "(\(expense.note!))" : "")"
            }
            cell!.detailTextLabel?.text = expense.categoryName ?? ""
        }
        
        return cell!
    }
}
