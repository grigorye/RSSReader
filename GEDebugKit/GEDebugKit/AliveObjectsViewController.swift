//
//  AliveObjectsViewController.swift
//  GEDebugKit
//
//  Created by Grigorii Entin on 08/12/2017.
//  Copyright © 2017 Grigory Entin. All rights reserved.
//

import UIKit

class AliveObjectsViewController : UITableViewController {
    
    var aliveObjects : [String : [WeakRefernece<AnyObject>]] = [:]
    lazy var aliveObjectsClassNames: [String] = aliveObjects.keys.sorted()
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return aliveObjects.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "aliveObject", for: indexPath) … {
            
            let className = aliveObjectsClassNames[indexPath.row]
            let objects = aliveObjects[className]!
            $0.textLabel!.text = "\(className)"
            $0.detailTextLabel!.text = "\(objects.count)"
        }
        return cell
    }
}
