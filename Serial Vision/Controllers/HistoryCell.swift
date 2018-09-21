//
//  HistoryCell.swift
//  Serial Vision
//
//  Created by Brandon Roehl on 9/20/18.
//  Copyright © 2018 Jamf. All rights reserved.
//

import UIKit

class HistoryCell: UITableViewCell {

    @IBOutlet weak var deviceName: UILabel?
    @IBOutlet weak var serialNumber: UILabel?
    @IBOutlet weak var dateLabel: UILabel?
    
    var history: CoreHistory! {
        didSet {
            let computer = CoreComputer.get(serial: history.serialNumber)
            
            self.deviceName?.text = computer?.deviceName
            self.serialNumber?.text = history.serialNumber
            
            if let date = history.date as Date? {
                self.dateLabel?.text = DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .short)
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
