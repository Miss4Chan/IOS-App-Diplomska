//
//  InitController.swift
//  ElderyCare
//
//  Created by Despina Misheva on 23.9.24.
//

import UIKit

class InitController: UIViewController{

    @IBOutlet weak var logo_main: UIImageView!
    
    override func viewDidLoad() {
        let image = UIImage(named: "Logo_elderly_care_supporting")
        logo_main.image = image
    }
}
