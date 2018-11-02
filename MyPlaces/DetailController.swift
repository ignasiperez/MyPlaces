//
//  DetailController.swift
//  MyPlaces
//
//  Created by iMac on 2/10/18.
//  Copyright © 2018 Ignasi Pérez. All rights reserved.
//

import UIKit

class DetailController: UIViewController,
                        UIPickerViewDelegate, UIPickerViewDataSource,
                        UIImagePickerControllerDelegate,
                        UINavigationControllerDelegate,
                        UITextViewDelegate, UITextFieldDelegate
{
    //  *******************************************************************
    //  MARK: - Instance Properties
    //
    var place: Place? = nil
    
    let pickerElems1 = ["Generic place", "Toutistic place"]
    
    var keyboardHeight: CGFloat!
    var activeField: UIView!
    var lastOffset: CGPoint!
    
    var notificationCenter: NotificationCenter!
    
    @IBOutlet weak var constraintHeight: NSLayoutConstraint!
    @IBOutlet weak var viewPicker: UIPickerView!
    @IBOutlet weak var imagePicked: UIImageView!
    
    @IBOutlet weak var textDescription: UITextView!
    @IBOutlet weak var textName: UITextField!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var btnUpdate: UIButton!

    
    //  *******************************************************************
    //  MARK: - @IBActions
    //
    //  PLA2 - 4.1
    //
    /// If the operation is new, we create an object of type Place or PlaceTourist
    /// depending on the selection in the UIPickerView
    @IBAction func newOrUpdatePressed(_ sender: UIButton)
    {
        let manager = ManagerPlaces.getInstance()
        
        let name = textName.text!
        let description = textDescription.text!
        
        
        if place == nil // NEW
        {
            let indexPlacesTypes: Int = viewPicker.selectedRow(inComponent: 0)
            
            var data: Data? = nil
            if imagePicked.image != nil {
                data = imagePicked.image!.jpegData(compressionQuality: 1.0)
            }
            
            var pl: Place? = nil
            if indexPlacesTypes == 0
            {
                pl = Place(
                    name: name,
                    description: description,
                    image_in: data)
            }
            else if indexPlacesTypes == 1
            {
                pl = PlaceTourist(
                    name: name,
                    description: description,
                    discount_tourist: "10€",
                    image_in: data)
            }
            
            pl?.location = ManagerLocation.getLocation()
            
            manager.append(pl!)
        }
        else // UPDATE
        {
            place!.name = name
            place!.description = description
        }
        
        manager.store()
        
        dismiss(animated: true, completion: nil)
        
        manager.updateObservers()
    }
    
    
    @IBAction func selectImagePressed(_ sender: Any)
    {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self     // Protocol UIImagePickerControllerDelegate
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = false
        
        // present(...) - Class UIViewController
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    
    //  PLA2 - 4.2
    //
    @IBAction func removePressed(_ sender: Any)
    {
        if place != nil {   // UPDATE
            ManagerPlaces.getInstance().remove(place!)
        }
        
        ManagerPlaces.getInstance().updateObservers()
        
        dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func cancelPressed(_ sender: Any)
    {
        dismiss(animated: true, completion: nil)
    }
    
    
    
    //  *******************************************************************
    //  MARK: - Overrided methods
    //
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        constraintHeight.constant = 400
        
        viewPicker.delegate = self      // Protocol UIPickerViewDelegate
        viewPicker.dataSource = self    // Protocol UIPickerViewDataSource
        
        softKeyboardControl()
        
        loadVisualComponents()
    }
    
    
    override func viewDidDisappear(_ animated: Bool)
    {
        super.viewDidDisappear(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    //  *******************************************************************
    //  MARK: - LOAD VISUAL COMPONENTS in the view
    //
    private func loadVisualComponents()
    {
        textName.text = ""
        textDescription.text = ""
        
        if place != nil  // UPDATE
        {
            let manager = ManagerPlaces.getInstance()
            
            textName.text = place!.name
            textDescription.text = place!.description
            
            imagePicked.contentMode = .scaleAspectFit
            
            imagePicked.image = UIImage(contentsOfFile: manager.getPathImage(p: place!))
            
            viewPicker.selectRow(place!.type.rawValue, inComponent: 0, animated: true)
            
            btnUpdate.setTitle("Update", for: .normal)
            btnUpdate.setTitle("Update", for: .highlighted)
            
            var indexPlacesTypes = 0
            indexPlacesTypes = place!.type.rawValue
            if place!.type == Place.PlacesTypes.TouristicPlace
            {
                indexPlacesTypes = 1
            }
            viewPicker.selectRow(indexPlacesTypes, inComponent: 0, animated: false)
        }
        else  // NEW
        {
            btnUpdate.setTitle("New", for: .normal)
            btnUpdate.setTitle("New", for: .highlighted)
        }
    }
    
    
    
    //  *******************************************************************
    //  MARK: - SOFT KEYBOARD control and interaction
    //
    //  PLA2 - 3.2.4
    //
    private func softKeyboardControl()
    {
        //  init(target: Any?, action: Selector?) - class UIGestureRecognizer
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(
            self,
            selector: #selector(hideKeyboard),
            name: UIResponder.keyboardWillHideNotification,
            object: nil)
        
        let strNotificationCenterDescription =  notificationCenter.description
        
        notificationCenter.addObserver(
            self,
            selector: #selector(showKeyboard),
            name: UIResponder.keyboardWillShowNotification,
            object: nil)
        
        textName.delegate = self
        textDescription.delegate = self
    }
    
    
    //  PLA2 - 3.2.6
    //
    //  When you apply @objc to a method it instructs Swift to make that method
    //  available to Objective-C as well as Swift code.
    //
    /// When we show the keyboard we reposition the UIScrollView
    @objc func showKeyboard(notification: Notification)
    {
        if (activeField != nil)
        {
            let userInfo = notification.userInfo
            let keyboardScreenEndFrame = (
                userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
            
            // func convert(_ rect: CGRect, from view: UIView?) -> CGRect
            let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
            
            keyboardHeight = keyboardViewEndFrame.size.height
            
            let distanceToBottom = self.scrollView.frame.size.height -
                (activeField?.frame.origin.y)! -
                (activeField?.frame.size.height)!
            let collapseSpace = keyboardHeight - distanceToBottom
            if collapseSpace > 0
            {
                scrollView.setContentOffset(
                    CGPoint(x: self.lastOffset.x, y: collapseSpace + 10),
                    animated: false)
                
                constraintHeight.constant += self.keyboardHeight
            }
            else
            {
                keyboardHeight = nil
            }
        }
    }
    
    
    //  PLA2 - 3.2.7
    //
    /// Pressing outside the UITextView the keyboard is closed
    @objc func dismissKeyboard()
    {
        view.endEditing(true)   // .endEditing(...) - Class UIView
    }
    
    
    //  PLA2 - 3.2.8
    //
    /// When the keyboard is closed we reposition the UIScrollView
    @objc func hideKeyboard(notification: Notification)
    {
        if keyboardHeight != nil
        {
            self.scrollView.contentOffset = CGPoint(x: self.lastOffset.x, y: self.lastOffset.y)
            self.constraintHeight.constant -= self.keyboardHeight
        }
        keyboardHeight = nil
    }
    
    
    //  *******************************************************************
    //  MARK: - UIPickerView Protocols
    //
    //  Protocol UIPickerViewDatasource
    /// Called by the picker view when it needs the number of components.
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    
    //  Protocol UIPickerViewDatasource
    /// Called by the picker view when it needs the number of rows for a specified component.
    /// Required.
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerElems1.count
    }
    
    
    /// Protocol UIPickerViewDelegate
    /// Called by the picker view when it needs the title to use for a given row in a given component.
    func pickerView(_ pickerView: UIPickerView,
                    titleForRow row: Int,
                    forComponent component: Int) -> String?
    {
        return pickerElems1[row]
    }

    
    
    
    //  *******************************************************************
    //  MARK: - UITextField and UITextView Protocols
    //  Used to know which UITextView we want to edit
    //  PLA2 - 3.2.5
    //
    //  Protocol UITextViewDelegate
    /// Asks the delegate if editing should begin in the specified text view.
    @objc func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        activeField = textView
        lastOffset = self.scrollView.contentOffset
        return true
    }
    
    
    
    //  Protocol UITextViewDelegate
    /// Asks the delegate if editing should stop in the specified text view.
    @objc func textViewShouldEndEditing(_ textView: UITextView) -> Bool
    {
        if activeField == textView
        {
            activeField?.resignFirstResponder()     // .resignFirstResponder() - Class UIView
            activeField = nil
        }
        return true
    }
    
    
    //  Protocol UITextFieldDelegate
    /// Asks the delegate if editing should begin in the specified text field
    @objc func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool
    {
        activeField = textField
        lastOffset = self.scrollView.contentOffset
        return true
    }
    
    
    //  Protocol UITextFieldDelegate
    /// Asks the delegate if editing should stop in the specified text field.
    @objc func textFieldShouldEndEditing(_ textField: UITextField) -> Bool
    {
        if activeField == textField
        {
            activeField?.resignFirstResponder()     // .resignFirstResponder() - Class UIView
            activeField = nil
        }
        return true
    }
    
    
    
    //  ********************************************************************
    //  MARK: - UIImagePickerController Protocols
    //  PLA2 - 3.1
    //
    //  Protocol UIImagePickerControllerDelegate
    ///  Tells the delegate that the user picked a still image or movie.
    @objc func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any])
    {
        view.endEditing(true)       // view... - Class UIViewController
        
        // var contentMode - Class UIView
        // enumeration UIView.ContentMode
        imagePicked.contentMode = .scaleAspectFit
        
        // struct InfoKey - UIImagePickerControllerDelegate
        let image = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        imagePicked.image = image
        
        dismiss(animated: true, completion: nil)    // dismiss(...) - Class UIViewController
    }
    
    //  Protocol UIImagePickerControllerDelegate
    /// Tells the delegate that the user cancelled the pick operation.
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}