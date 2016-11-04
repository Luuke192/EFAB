//
//  ExpenseViewController.swift
//  EFAB
//
//  Created by Lucas Lell on 11/3/16.
//  Copyright © 2016 Luuke192. All rights reserved.
//

import UIKit
import SnapKit
import MBProgressHUD

// Step 16: Create class
class ExpenseViewController: UIViewController {
    @IBOutlet weak var amountField: UITextField!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var datePickerView: UIView!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var noteField: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    var showDate = false
    
    var category: Category!
    
    var currentTextfield: UITextField?
    
    // Step 17: currentWeek and pastWeek constants, week/pastExpenses arrays, refreshControl
    let currentWeek = 0
    let pastWeeks = 1
    
    var weekExpenses : [Expense] = []
    var pastExpenses : [Expense] = []
    
    let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Step 16: setup dateLabel, datePicker, and saveButton
        dateLabel.text = datePicker.date.toString(.custom(Constants.monthDayYear))
        
        datePicker.isHidden = true
        datePicker.alpha = 0.0
        datePickerView.snp.remakeConstraints { (make) -> Void in
            make.height.equalTo(0)
        }
        
        saveButton.isEnabled = false
        
        // Step 17:
        refreshControl.addTarget(self, action: #selector(ExpenseViewController.retrieveExpenses), for: .valueChanged)
        tableView.addSubview(refreshControl)
    }
    
    // Step 17: call retrieveExpenses in viewWillAppear
    override func viewWillAppear(_ animated: Bool) {
        retrieveExpenses()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // Step 17: retrieve expenses
    func retrieveExpenses() {
        MBProgressHUD.showAdded(to: view, animated: true)
        
        let today = Date()
        let sunday = today.dateAtStartOfWeek()
        
        let expenses = Expense(categoryId: self.category.id!)
        expenses.requestType = Expense.RequestType.recent
        WebServices.shared.getObjects(expenses) { (objects, error) -> Void in
            if let objects = objects {
                self.weekExpenses = []
                self.pastExpenses = []
                for expense in objects {
                    if let date = expense.date {
                        if date.isSameWeekAsDate(sunday) {
                            self.weekExpenses.append(expense)
                        } else {
                            self.pastExpenses.append(expense)
                        }
                    }
                }
            } else {
                self.present(Utils.createAlert(message: error ?? Constants.JSON.unknownError), animated: true, completion: nil)
            }
            
            MBProgressHUD.hide(for: self.view, animated: true)
            
            self.refreshControl.endRefreshing()
            self.tableView.reloadData()
        }
    }
    
    
    // MARK: - Private functions
    // Step 16: hideDatePicker function
    fileprivate func hideDatePicker() {
        self.datePicker.isHidden = true
        self.datePickerView.snp.remakeConstraints { (make) -> Void in
            make.height.equalTo(0)
        }
        UIView.animate(withDuration: 0.25, animations: { () -> Void in
            self.datePicker.alpha = 0.0
            self.view.layoutIfNeeded()
        })
    }
    
    
    // MARK: - IBActions
    // Step 16: IBActions for saveTapped, buttonTapped, dateChanged
    @IBAction func saveTapped(_ sender: UIBarButtonItem) {
        saveButton.isEnabled = false
        let theAmount = (amountField.text! as NSString).doubleValue
        let note = noteField.text!
        let date = Utils.adjustedTime(datePicker.date)
        
        let newExpense = Expense(amount: theAmount, categoryId: self.category.id!, date: date, note: note)
        MBProgressHUD.showAdded(to: view, animated: true)
        WebServices.shared.postObject(newExpense) { (object, error) -> Void in
            MBProgressHUD.hide(for: self.view, animated: true)
            if let _ = object {
                self.amountField.text = ""
                self.noteField.text = ""
                self.datePicker.date = Date()
                self.dateChanged(self.datePicker)
                self.retrieveExpenses()
                self.saveButton.isEnabled = true
                self.present(Utils.createAlert("Success", message: "Your expense has been saved", dismissButtonTitle: "OK"), animated: true, completion: nil)
            } else {
                self.present(Utils.createAlert(message: "There was an error saving your expense.  Please try again"), animated: true, completion: nil)
                self.saveButton.isEnabled = true
            }
        }
    }
    
    @IBAction func buttonTapped(_ sender: UIButton) {
        if let textfield = currentTextfield {
            textfield.resignFirstResponder()
            currentTextfield = nil
        }
        self.view.layoutIfNeeded()
        showDate = !showDate
        if showDate {
            self.datePicker.isHidden = false
            self.datePickerView.snp.remakeConstraints { (make) -> Void in
                make.height.equalTo(202)
            }
            UIView.animate(withDuration: 0.25, animations: { () -> Void in
                self.datePicker.alpha = 1.0
                self.view.layoutIfNeeded()
            })
        } else {
            hideDatePicker()
        }
    }
    
    @IBAction func dateChanged(_ sender: UIDatePicker) {
        dateLabel.text = datePicker.date.toString(.custom(Constants.monthDayYear))
    }
}

// MARK: - UITextField Delegate
// Step 16: UITextFieldDelegate
extension ExpenseViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == amountField {
            let valid = Utils.isNumber(string)
            if valid {
                var text: NSString = textField.text! as NSString
                text = text.replacingCharacters(in: range, with: string) as NSString
                saveButton.isEnabled = text.length > 0
            }
            return valid
        }
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        currentTextfield = textField
        if showDate {
            showDate = !showDate
            hideDatePicker()
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        currentTextfield = nil
    }
}


// MARK: - UITableView Delegate/Datasource
// Step 17: UITableViewDelegate/Datasource
extension ExpenseViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case currentWeek:
            return weekExpenses.count
        case pastWeeks:
            return pastExpenses.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case currentWeek:
            return "Expenses This Week"
        case pastWeeks:
            return "Previous Expenses"
        default:
            return ""
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ExpenseCell")!
        cell.textLabel?.lineBreakMode = .byTruncatingTail
        
        let expense: Expense!
        if (indexPath as NSIndexPath).section == currentWeek {
            expense = self.weekExpenses[(indexPath as NSIndexPath).row]
        } else {
            expense = self.pastExpenses[(indexPath as NSIndexPath).row]
        }
        
        if let amount = expense.amount {
            cell.textLabel?.text = "\(String(format: "$%.2f", amount)) \(expense.note! != "" ? "(\(expense.note!))" : "")"
        }
        cell.detailTextLabel?.text = expense.dateDay()
        
        return cell
    }
}
