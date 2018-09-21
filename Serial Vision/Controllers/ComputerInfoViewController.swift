//
//  ComputerInfoViewController.swift
//  Serial Vision
//
//  Created by Brandon Roehl on 9/21/18.
//  Copyright © 2018 Jamf. All rights reserved.
//

import UIKit

class ComputerInfoViewController: UITableViewController {
    
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var serialNumberLabel: UILabel!
    @IBOutlet weak var deviceNameLabel: UILabel!
    @IBOutlet weak var buildingNameLabel: UILabel!
    @IBOutlet weak var departmentNameLabel: UILabel!
    @IBOutlet weak var managedLabel: UILabel!

    var serialNumber: String! {
        didSet {
            self.computer = CoreComputer.get(serial: self.serialNumber)
            print("\(self.serialNumber ?? "nil") : \(String(describing: self.computer))")
        }
    }
    var computer: CoreComputer! {
        didSet {
            self.updateView()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    @objc func dismissSelf() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func allowDismiss() {
        let item = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissSelf))
        self.navigationItem.leftBarButtonItem = item
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.updateView()
    }
    
    func updateView() {
        guard self.computer != nil, self.isViewLoaded else { return }
        
        self.serialNumberLabel.text = self.serialNumber
        
        self.usernameField.text = self.computer.username
        self.deviceNameLabel.text = self.computer.deviceName
        self.buildingNameLabel.text = self.computer.building
        self.departmentNameLabel.text = self.computer.department
        self.managedLabel.text = self.computer.managed ? "Yes" : "No"
        
        self.updateImage()
    }
    
    func updateImage() {
        if let text = self.usernameField.text {
            self.userImageView.image = UIImage(named: text)
        }
    }

    @IBAction func usernameChanged(_ sender: UITextField) {
        self.computer.username = sender.text
        self.updateImage()
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
