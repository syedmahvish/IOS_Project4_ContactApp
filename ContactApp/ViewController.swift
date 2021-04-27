//
//  ViewController.swift
//  ContactApp
//
//  Created by Mahvish Syed on 25/04/21.
//  Copyright © 2021 Mahvish Syed. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    
    @IBOutlet weak var profilePictureImageView: UIImageView!
    
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var mobileTextField: UITextField!
    
    @IBOutlet weak var emailTextField: UITextField!
    
    var person = Person()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var gesture = UITapGestureRecognizer(target: self, action: #selector(dismissView))
        gesture.cancelsTouchesInView = false
        self.view.addGestureRecognizer(gesture)
    }
    
    @objc func dismissView(){
        self.view.endEditing(true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let pic = person.imageURLlarge as? String{
            let url = URL(string: pic)
            
            DispatchQueue.global().async {
                do{
                    let data = try Data(contentsOf: url!)
                    DispatchQueue.main.async {
                         self.profilePictureImageView.image = UIImage(data: data)
                    }
                }catch{}
            }
        }
        
        if let name = person.name as? String{
            nameTextField.text = name
        }
        
        if let mobile = person.number as? String{
            mobileTextField.text = mobile
        }
        
        if let email = person.email as? String{
            emailTextField.text = email
        }
    }


    @IBAction func uploadProfilePicture(_ sender: UIButton) {
    }
    
    
}

