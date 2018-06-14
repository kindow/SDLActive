//
//  ViewController.swift
//  TestSDL
//
//  Created by De biasi, Anna (A.) on 6/8/18.
//  Copyright © 2018 De biasi, Anna (A.). All rights reserved.
//

import UIKit

class Labeling: UIViewController {
    
    @IBOutlet weak var labelOne: UILabel!
    @IBOutlet weak var labelTwo: UILabel!
    @IBOutlet weak var labelThree: UILabel!
    @IBOutlet weak var labelFour: UILabel!
    @IBOutlet weak var labelFive: UILabel!
    @IBOutlet weak var labelSix: UILabel!
    @IBOutlet weak var labelSeven: UILabel!
    
    var apiStruct: APIStruct?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let textSix = apiStruct!.assetDescriptions.isEmpty ? "Description Unavailable" : apiStruct!.assetDescriptions[0].description
        
        labelSix.text = textSix.htmlToString
        labelSix.numberOfLines = 0
        labelSix.adjustsFontSizeToFitWidth = true
        
        labelOne.text = apiStruct!.organization.organizationName.isEmpty ? "Organization Unavailable" : apiStruct!.organization.organizationName
        labelOne.numberOfLines = 0
        labelOne.adjustsFontSizeToFitWidth = true
        
        labelTwo.text = apiStruct!.assetPrices.isEmpty ? "Price Unavailable" : "Price: $\(String(apiStruct!.assetPrices[0].priceAmt))"
        labelTwo.numberOfLines = 0
        labelTwo.adjustsFontSizeToFitWidth = true
        
        labelFour.text = apiStruct!.place.addressLine1Txt.isEmpty || apiStruct!.place.stateProvinceCode.isEmpty ||  apiStruct!.place.cityName.isEmpty ? "Address Unavailable" : "Address: \(String(apiStruct!.place.addressLine1Txt)) \(apiStruct!.place.stateProvinceCode), \(apiStruct!.place.cityName)"
        labelFour.numberOfLines = 0
        labelFour.adjustsFontSizeToFitWidth = true
        
        labelFive.text = apiStruct!.organization.primaryContactPhone.isEmpty ? "Contact Unavailable" : "Contact Number: \(String(apiStruct!.organization.primaryContactPhone))"
        labelFive.numberOfLines = 0
        labelFive.adjustsFontSizeToFitWidth = true
        
        func getProperDate(from date: String) -> String? {
            // date format is YYYY-MM-DD
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            guard let date = dateFormatter.date(from: date) else { return nil }
            dateFormatter.dateFormat = "MMMM dd, YYYY"
            let properDate = dateFormatter.string(from: date)
            return properDate
        }
        
        labelSeven.text = apiStruct!.salesStartDate.isEmpty ? "Sales Start Date Unavailable" : "Sales Start Date: \((getProperDate(from: apiStruct!.salesStartDate))!)"
        labelSeven.numberOfLines = 0
        labelSeven.adjustsFontSizeToFitWidth = true
        
        labelThree.text = apiStruct!.salesEndDate.isEmpty ? "Sales End Date Unavailable" :  "Sales End Date: \((getProperDate(from: apiStruct!.salesEndDate))!)"
        labelThree.numberOfLines = 0
        labelThree.adjustsFontSizeToFitWidth = true
    }
}

extension String {
    var htmlToAttributedString: NSAttributedString? {
        guard let data = data(using: .utf8) else { return NSAttributedString() }
        do {
            return try NSAttributedString(data: data, options: [NSAttributedString.DocumentReadingOptionKey.documentType:  NSAttributedString.DocumentType.html], documentAttributes: nil)
        } catch {
            return NSAttributedString()
        }
    }
    var htmlToString: String {
        return htmlToAttributedString?.string ?? ""
    }
}


