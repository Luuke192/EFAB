//
//  ViewController.swift
//  EFAB
//
//  Created by Lucas Lell on 10/31/16.
//  Copyright © 2016 Luuke192. All rights reserved.
//

import UIKit
// Step 3: import Alamofire
import Alamofire
// Step 4: import Freddy
import Freddy

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Step 3: call the Test endpoint (most of this will be commented out in Step 5
        let test = Test()
        print("making call")
        //        request(WebServices.AuthRouter.RESTRequest(test)).response { (request, response, data, error) in
        //            print("call returned")
        //
        //            // Step 4: process response
        //            var testReturn: Test?
        //            var errorString: String?
        //
        //            let statusCode = response?.statusCode
        //            if let statusCode = statusCode {
        //                switch statusCode {
        //                case 200:
        //                    if let data = data {
        //                        let json = JSON(data: data)
        //                        testReturn = Test(json: json)
        //                    } else {
        //                        errorString = Constants.JSON.unknownError
        //                    }
        //                case 400:
        //                    errorString = Constants.JSON.badRequest
        //                default:
        //                    errorString = Constants.JSON.unknownError
        //                }
        //            }
        //
        //            if let testReturn = testReturn {
        //                print(testReturn.description())
        //            } else {
        //                print(errorString ?? Constants.JSON.unknownError)
        //            }
        //        }
        
        // Step 5: Comment out code above and make call with generic function
        WebServices.shared.getObject(test) { (object, error) in
            print("call returned")
            if let object = object {
                print(object.description())
            } else {
                print(error ?? Constants.JSON.unknownError)
            }
        }
        print("call made")
        
        // Step 6: Add calls to create post and get all posts
        let testPost = Test(userId: 1, title: "test title", body: "test body")
        WebServices.shared.postObject(testPost) { (object, error) in
            if let object = object {
                print("test post result: \(object.description())")
            } else {
                print("test post failed")
            }
        }
        
        let getPostsTest = Test()
        getPostsTest.requestType = Test.RequestType.getPosts
        WebServices.shared.getObjects(getPostsTest) { (objects, error) in
            if let objects = objects {
                print("got \(objects.count) items")
            } else {
                print("get posts failed")
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
