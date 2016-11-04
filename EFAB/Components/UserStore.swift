//
//  UserStore.swift
//  EFAB
//
//  Created by Lucas Lell on 11/3/16.
//  Copyright © 2016 Luuke192. All rights reserved.
//

import Foundation

class UserStore {
    static let shared = UserStore()
    
    // Step 19: Add monthExpenses, currentMonth/Year
    var monthExpenses: [Int: [Int: [Int: [Expense]]]] = [:]
    var currentMonth: Int?
    var currentYear: Int?
    
    func login(_ loginUser: User, completion:@escaping (_ success: Bool, _ error: String?) -> Void) {
        WebServices.shared.authUser(loginUser) { (user, error) -> () in
            if let user = user {
                WebServices.shared.setAuthToken(user.token, expiration: user.expirationDate)
                completion(true, nil)
            } else {
                completion(false, error)
            }
        }
    }
    
    func register(_ registerUser: User, completion:@escaping (_ success: Bool, _ error: String?) -> Void) {
        WebServices.shared.registerUser(registerUser) { (user, error) -> () in
            if let user = user {
                WebServices.shared.setAuthToken(user.token, expiration: user.expirationDate)
                completion(true, nil)
            } else {
                completion(false, error)
            }
        }
    }
    
    func logout(_ completion:() -> Void) {
        WebServices.shared.clearUserAuthToken()
        completion()
    }
    
    // Step 19: getExpenses
    func getExpenses(_ month: Int, year: Int) {
        if (currentMonth != month || currentYear != currentYear) {
            currentMonth = month
            currentYear = year
            let expense = Expense(month: month, year: year)
            WebServices.shared.getObjects(expense) { (objects, error) in
                if let objects = objects {
                    var expenses: [Int: [Expense]] = [:]
                    for expense in objects {
                        if let date = expense.date {
                            var dayExpenses = expenses[date.day()] ?? []
                            dayExpenses.append(expense)
                            expenses[date.day()] = dayExpenses
                        }
                    }
                    var yearArray = self.monthExpenses[year] ?? [:]
                    yearArray[month] = expenses
                    self.monthExpenses[year] = yearArray
                }
                
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.newExpensesFound), object: nil)
            }
        }
    }
}
