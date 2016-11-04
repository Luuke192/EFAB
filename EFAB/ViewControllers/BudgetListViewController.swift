//
//  BudgetListViewController.swift
//  EFAB
//
//  Created by Lucas Lell on 11/3/16.
//  Copyright © 2016 Luuke192. All rights reserved.
//

import UIKit
// Step 13: Import MBProgressHUD
import MBProgressHUD

// Step 8: Create class
class BudgetListViewController: UIViewController, SegueHandlerType {
    // Step 10: Add Tableview IBOutlet
    @IBOutlet weak var tableView: UITableView!
    
    // Step 13: Add other IBOutlets
    @IBOutlet weak var timeControl: UISegmentedControl!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var forwardButton: UIButton!
    @IBOutlet weak var todayButton: UIButton!
    
    // Step 12: create SegueIdentifier enum
    enum SegueIdentifier: String {
        case PresentLoginNoAnimation
        case PresentLogin
        case ShowAddCategory
        case ShowCalendar
        case ShowAddExpense
    }
    
    // Step 13: UIRefreshControl, currentDate, week/monthCategories, and week/month constants
    let refreshControl = UIRefreshControl()
    var currentDate = Utils.adjustedTime()
    
    var weekCategories: [Date: [Category]] = [:]
    var monthCategories: [Date: [Category]] = [:]
    
    let weekIndex = 0
    let monthIndex = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Step 13: setup refresh control, date label, and today button
        refreshControl.addTarget(self, action: #selector(BudgetListViewController.loadCategories), for: .valueChanged)
        tableView.addSubview(refreshControl)
        
        dateLabel.text = getDateRange()
        todayButton.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Step 8: Load LoginVC
        if !WebServices.shared.userAuthTokenExists() || WebServices.shared.userAuthTokenExpired() {
            //            performSegueWithIdentifier("PresentLoginNoAnimation", sender: self)
            
            // Step 12: comment out line above and switch to enum
            performSegueWithIdentifier(.PresentLoginNoAnimation, sender: self)
        } else { // Step 13: add else statement
            loadCategories()
        }
        
        // Step 13: add NSNotification
        NotificationCenter.default.addObserver(self, selector: #selector(BudgetListViewController.loadCategories), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
    }
    
    // Step 13: add viewWillDisappear and remove observer
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // Step 13: create loadCategories function
    func loadCategories() {
        var showSpinner = false
        let category: Category!
        if timeControl.selectedSegmentIndex == weekIndex {
            category = Category(week: currentDate)
            if getCurrentWeek().isEmpty {
                showSpinner = true
            }
        } else {
            category = Category(month: currentDate)
            if getCurrentMonth().isEmpty {
                showSpinner = true
            }
        }
        
        if showSpinner {
            MBProgressHUD.showAdded(to: view, animated: true)
        }
        
        WebServices.shared.getObjects(category) { (objects, error) -> Void in
            MBProgressHUD.hide(for: self.view, animated: true)
            self.refreshControl.endRefreshing()
            if var categories = objects {
                categories.sort(by: { (c1, c2) -> Bool in
                    switch (c1.name, c2.name) {
                    case let (name1?, name2?):
                        return name1 < name2
                    case (nil, _?):
                        return true
                    default:
                        return false
                    }
                })
                if self.timeControl.selectedSegmentIndex == self.weekIndex {
                    self.weekCategories[self.currentDate.dateAtStartOfWeek().dateAtStartOfDay()] = categories
                } else {
                    self.monthCategories[self.currentDate.dateAtTheStartOfMonth().dateAtStartOfDay()] = categories
                }
                self.tableView.reloadData()
            } else {
                self.present(Utils.createAlert(message: error ?? Constants.JSON.unknownError), animated: true, completion: nil)
            }
        }
    }
    
    
    // MARK: - Private Functions
    // Step 13: getCurrentWeek, getCurrentMonth, and getDateRange functions
    fileprivate func getCurrentWeek() -> [Category] {
        return weekCategories[currentDate.dateAtStartOfWeek().dateAtStartOfDay()] ?? []
    }
    
    fileprivate func getCurrentMonth() -> [Category] {
        return monthCategories[currentDate.dateAtTheStartOfMonth().dateAtStartOfDay()] ?? []
    }
    
    fileprivate func getDateRange() -> String {
        let timePeriod = timeControl.selectedSegmentIndex
        switch timePeriod {
        case weekIndex:
            let startDate = currentDate.dateAtStartOfWeek()
            let endDate = currentDate.dateAtEndOfWeek()
            let startMonth = startDate.toString(.custom("MMM"))
            let endMonth = endDate.toString(.custom("MMM"))
            if startDate.year() == endDate.year() {
                if startDate.month() == endDate.month() {
                    return "\(startMonth) \(startDate.day()) - \(endDate.day()), \(startDate.year())"
                } else {
                    return "\(startMonth) \(startDate.day()) - \(endMonth) \(endDate.day()), \(startDate.year())"
                }
            } else {
                return "\(startMonth) \(startDate.day()), \(startDate.year()) - \(endMonth) \(endDate.day()), \(endDate.year())"
            }
        default:
            return "\(currentDate.toString(.custom("MMM"))) \(currentDate.year())"
        }
    }
    
    // Step 14: Create getCategories function
    fileprivate func getCategories() -> [Category] {
        if timeControl.selectedSegmentIndex == weekIndex {
            return getCurrentWeek()
        } else {
            return getCurrentMonth()
        }
    }
    
    // Step 15: setupDateHeader function
    fileprivate func setupDateHeader() {
        switch timeControl.selectedSegmentIndex {
        case weekIndex:
            if currentDate.isSameWeekAsDate(Date()) {
                currentDate = Utils.adjustedTime()
                todayButton.isHidden = true
            } else {
                todayButton.isHidden = false
            }
            
            if !getCurrentWeek().isEmpty {
                tableView.reloadData()
            }
        default:
            if currentDate.month() == Date().month() && currentDate.year() == Date().year() {
                currentDate = Utils.adjustedTime()
                todayButton.isHidden = true
            } else {
                todayButton.isHidden = false
            }
            
            if !getCurrentMonth().isEmpty {
                tableView.reloadData()
            }
        }
        dateLabel.text = getDateRange()
        loadCategories()
    }
    
    // MARK: - IBActions
    // Step 9: Add Logout Function
    @IBAction func logoutTapped(_ sender: AnyObject) {
        UserStore.shared.logout {
            //            self.performSegueWithIdentifier("PresentLogin", sender: self)
            
            // Step 12: comment out line above and switch to enum
            self.performSegueWithIdentifier(.PresentLogin, sender: self)
        }
    }
    
    // Step 15: Add IBAction for changing date and time period
    @IBAction func timePeriodChanged(_ sender: AnyObject) {
        setupDateHeader()
    }
    
    @IBAction func backTapped(_ sender: AnyObject) {
        switch timeControl.selectedSegmentIndex {
        case weekIndex:
            currentDate = currentDate.dateBySubtractingDays(7)
        default:
            let day = currentDate.day()
            currentDate = currentDate.dateAtTheStartOfMonth().dateBySubtractingDays(1)
            currentDate = currentDate.dateAtTheStartOfMonth().dateByAddingDays(min(day - 1, currentDate.monthDays() - 1))
        }
        setupDateHeader()
    }
    
    @IBAction func forwardTapped(_ sender: AnyObject) {
        switch timeControl.selectedSegmentIndex {
        case weekIndex:
            currentDate = currentDate.dateByAddingDays(7)
        default:
            let day = currentDate.day()
            currentDate = currentDate.dateAtTheStartOfMonth().dateByAddingDays(currentDate.monthDays())
            currentDate = currentDate.dateByAddingDays(min(day - 1, currentDate.monthDays() - 1))
        }
        setupDateHeader()
    }
    
    @IBAction func todayTapped(_ sender: AnyObject) {
        currentDate = Utils.adjustedTime()
        setupDateHeader()
    }
    
    
    // MARK: - Navigation
    // Step 16: shouldPerformSegueWithIdentifier prepareForSegue
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if let cell = sender as? UITableViewCell, let indexPath = tableView.indexPath(for: cell) , (indexPath as NSIndexPath).row == getCategories().count {
            return false
        }
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifierForSegue(segue) {
        case .ShowAddExpense:
            let vc = segue.destination as! ExpenseViewController
            let cell = sender as! CategoryCell
            vc.category = cell.category
        default:
            break
        }
    }
}


// MARK: - UITableView Methods
// Step 14: Create UITableViewDataSource/Delegate extension
extension BudgetListViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let categories = getCategories()
        return categories.count + 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: CategoryCell.self)) as! CategoryCell
        
        let categories = getCategories()
        
        if (indexPath as NSIndexPath).row < categories.count {
            let category = categories[(indexPath as NSIndexPath).row]
            
            cell.setupCell(category, total: false)
        } else {
            let category = Category()
            category.name = "\(timeControl.titleForSegment(at: timeControl.selectedSegmentIndex)!) Total"
            category.amount = categories.reduce(0.0) { $0 +++ $1.amount }
            cell.setupCell(category, total: true)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
    }
}


// Step 14: Custom operator for summing categories
infix operator +++
func +++ (a: Double?, b: Double?) -> Double {
    return (a ?? 0) + (b ?? 0)
}
