//
//  ComputerController.swift
//  Serial Vision
//
//  Created by Brandon Roehl on 9/20/18.
//  Copyright © 2018 Jamf. All rights reserved.
//

import UIKit

class ComputerController: UIViewController {
    
    var serialNumber: String! {
        didSet {
            self.computer = CoreComputer.get(serial: self.serialNumber)
        }
    }
    var computer: CoreComputer!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    func allowDismiss() {
        var item = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismiss(animated:completion:)))
        self.navigationItem.leftBarButtonItem = item
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print(self.serialNumber)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}