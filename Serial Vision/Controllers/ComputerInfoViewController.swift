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
    }

    @IBAction func usernameChanged(_ sender: UITextField) {
        print(sender.text ?? "empty")
    }
    
    /*
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }
    */

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
