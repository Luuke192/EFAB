//
//  Test.swift
//  EFAB
//
//  Created by Lucas Lell on 10/31/16.
//  Copyright © 2016 Luuke192. All rights reserved.
//

import Foundation
import Alamofire
import Freddy

// Step 3: Create Test model
class Test: NetworkModel {
    var userId: Int?
    var id: Int?
    var title: String?
    var body: String?
    
    // Step 6: Add RequestType
    enum RequestType {
        case getPost
        case getPosts
        case createPost
    }
    var requestType: RequestType = .getPost
    
    required init() {}
    
    required init(json: JSON) throws {
        userId = try? json.getInt(at: Constants.Test.userId)
        id = try? json.getInt(at: Constants.Test.id)
        title = try? json.getString(at: Constants.Test.title)
        body = try? json.getString(at: Constants.Test.body)
    }
    
    // Step 6: Add convenience init
    init(userId: Int, title: String, body: String) {
        self.userId = userId
        self.title = title
        self.body = body
        requestType = .createPost
    }
    
    func method() -> Alamofire.HTTPMethod {
        //        return .GET
        // Step 6: Comment out line above and add switch
        switch requestType {
        case .getPost, .getPosts:
            return .get
        default:
            return .post
        }
    }
    
    func path() -> String {
        //        return "/posts/1"
        // Step 6: Comment out line above and add switch
        switch requestType {
        case .getPost:
            return "/posts/1"
        case .getPosts:
            return "/posts"
        case .createPost:
            return "/posts"
        }
    }
    
    func toDictionary() -> [String: AnyObject]? {
        //        return nil
        // Step 6: Comment out line above and add switch
        switch requestType {
        case .createPost:
            var params: [String: AnyObject] = [:]
            
            params[Constants.Test.userId] = userId as AnyObject?? ?? 0 as AnyObject?
            params[Constants.Test.title] = title as AnyObject?? ?? "" as AnyObject?
            params[Constants.Test.body] = body as AnyObject?? ?? "" as AnyObject?
            
            return params
        default:
            return nil
        }
    }
    
    func description() -> String {
        var text = ""
        text += "title: \(title ?? "")\n"
        text += "body: \(body ?? "")\n"
        return text
    }
}
