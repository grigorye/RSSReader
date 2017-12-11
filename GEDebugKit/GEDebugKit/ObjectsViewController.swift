//
//  ObjectsViewController.swift
//  GEDebugKit
//
//  Created by Grigorii Entin on 11/12/2017.
//  Copyright © 2017 Grigory Entin. All rights reserved.
//

import UIKit

class ObjectsViewController : UITableViewController {

    struct Data {
        
        let className: String
        let objects: [WeakReference<AnyObject>]
    }
    
    var data: Data = Data(className: "", objects: [])
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return data.objects.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "object", for: indexPath) … {
            
            let textLabel = $0.textLabel!
            
            var unsafeObject = data.objects[indexPath.row]
            withUnsafePointer(to: &unsafeObject) {
                textLabel.text = "\($0)"
            }
        }
        
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "showDetail"?:
            let reference: WeakReference<AnyObject> = {
                let indexPath = tableView.indexPathForSelectedRow!
                return data.objects[indexPath.row]
            }()
            
            segue.destination as! ObjectDetailViewController … {
                
                $0.data = ObjectDetailViewController.Data(object: reference.object!)
            }
        default: ()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = String.localizedStringWithFormat(NSLocalizedString("%@", comment: ""), data.className)
    }
}
