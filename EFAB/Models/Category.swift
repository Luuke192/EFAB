//
//  Category.swift
//  EFAB
//
//  Created by Lucas Lell on 11/3/16.
//  Copyright © 2016 Luuke192. All rights reserved.
//

import UIKit
import Alamofire
import Freddy
import AFDateHelper

// Step 10: Create Model
class Category: NetworkModel {
    var id: Int?
    var name: String?
    var startDate: String?
    var endDate: String?
    var amount: Double?
    var requestType: RequestType = .create
    
    var searchDate: Date?
    
    enum RequestType {
        case create
        case week
        case month
    }
    
    required init() {}
    
    required init(json: JSON) throws {
        id = try? json.getInt(at: Constants.Category.id)
        name = try? json.getString(at: Constants.Category.name)
        amount = try? json.getDouble(at: Constants.Category.amount)
    }
    
    init(name: String, amount: Double) {
        self.name = name
        self.amount = amount
        self.requestType = .create
    }
    
    // Step 13: add month and week init functions
    init(month: Date) {
        requestType = .month
        searchDate = month
    }
    
    init(week: Date) {
        requestType = .week
        searchDate = week.dateAtStartOfWeek()
    }
    
    func method() -> Alamofire.HTTPMethod {
        switch requestType {
        case .create:
            return .post
        // Step 13: add default case
        default:
            return .get
        }
    }
    
    func path() -> String {
        switch requestType {
        case .create:
            return "/api/category/createCategory"
        case .week:
            return "/api/category/getCategory/year/\(searchDate!.year())/month/\(searchDate!.month())/day/\(searchDate!.day())"
        case .month:
            return "/api/category/getCategory/year/\(searchDate!.year())/month/\(searchDate!.month())"
        }
    }
    
    func toDictionary() -> [String: AnyObject]? {
        switch requestType {
        case .create:
            var params: [String: AnyObject] = [:]
            
            params[Constants.Category.name] = name as AnyObject?
            params[Constants.Category.amount] = amount as AnyObject?
            params[Constants.Category.startDate] = Utils.adjustedTime().toString(.iso8601(nil)) as AnyObject?
            
            return params
        default:
            return nil
        }
    }
}
