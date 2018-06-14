//
//  ViewController.swift
//  TestSDL
//
//  Created by De biasi, Anna (A.) on 6/8/18.
//  Copyright © 2018 De biasi, Anna (A.). All rights reserved.
//

import UIKit
import MapKit

//protocol delegate: class {
//    func didRequestMenuItems(event : String, callBack : @escaping ((_ apiData: [APIStruct]) -> ()))
//}


class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{
    // let access_key = "8auynm8hk7ejhq84pr64v77u"
    //@IBOutlet weak var textview: UITextView!
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    var apiStructData  = [APIStruct]()
    
    @IBOutlet weak var table: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        //getJson(str: "", nil)
    }
    
    func getJson(str: String) { //_ callBack: (()-> ())?
        self.spinner.startAnimating()
        let session = URLSession(configuration: .ephemeral, delegate: nil, delegateQueue: OperationQueue.main)
        let url = URL(string: "http://api.amp.active.com/v2/search?query=\(str)&category=event&start_date=2017-12-04..&near=Palo%20Alto,CA,US&radius=50&api_key=8auynm8hk7ejhq84pr64v77u")!
        let task = session.dataTask(with: url, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            guard let data = data else {
                return
            }
            guard let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) else {
                return
            }
            let dictJson = json as! [String : Any]
            for (key,_) in dictJson{
                if(key == "results"){
                    for result in dictJson["results"] as! [[String:Any]]{
                        let apiStruct = APIStruct(withData: result)
                        self.apiStructData.append(apiStruct!)
                    }
                }
            }
            // let str = self.soccerEventsData.description
            self.spinner.stopAnimating()
            self.spinner.isHidden = true
            self.table.reloadData()
            //callBack!([APIStruct]: apiStructData )
        })
        task.resume()
    }
    
    
    func getProperDate(from date: String) -> String? {
        // date format is YYYY-MM-DD
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-mm-dd"
        guard let date = dateFormatter.date(from: date) else { return nil }
        dateFormatter.dateFormat = "MMMM dd, YYYY"
        let properDate = dateFormatter.string(from: date)
        return properDate
    }
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return apiStructData.count
    }
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "cell0")
        let key   = (apiStructData[indexPath.row]).organization.organizationName
        let value = (apiStructData[indexPath.row]).salesEndDate
        let date = value[..<value.index(value.startIndex, offsetBy: 10)]
        var str = String(date)
        str = (getProperDate(from: str))!
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.text = "\(key): \(str)"
        return(cell)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "Labeling", sender: indexPath)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "Labeling"){
            let Labeling =   segue.destination as! Labeling
            let indexPath = sender as! IndexPath
            Labeling.apiStruct = apiStructData[indexPath.row]
        }
    }
    
    
    
}

//extension ViewController : delegate{
//    func didRequestMenuItems(event: String, callBack: @escaping (([APIStruct]) -> ())) {
//        getJson(str: event, callBack(()->()))    }
//}




