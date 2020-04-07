//
//  ViewController.swift
//  LoginWithFirebase
//
//  Created by 柿沼儀揚 on 2020/03/17.
//  Copyright © 2020 柿沼儀揚. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore
import PKHUD

//データ取得の変数
struct User {
    let name: String
    let creatAt: Timestamp
    let email: String
    

    init(dic: [String: Any]) {
        self.name = dic["name"] as! String
        self.creatAt = dic["creatAt"] as! Timestamp
        self.email = dic["email"] as! String
    }

}

class ViewController: UIViewController {

    @IBOutlet weak var RegisterButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBAction func toppedRegisterButton(_ sender: Any) {
        //Firebaseの認証処理
        handleAuthToFirebase()
    }
    
    @IBAction func toppedAlreadyacountButton(_ sender: Any) {
        //遷移
        let storyBoard = UIStoryboard(name: "Login", bundle: nil)
        let homeViewController = storyBoard.instantiateViewController(identifier: "LoginViewController")
            as! LoginViewController
        navigationController?.pushViewController(homeViewController, animated: true)
//        self.present(homeViewController, animated: true, completion: nil)
    }
    
    private func handleAuthToFirebase() {
        HUD.show(.progress, onView: view)
        //optional型なのでnilなら返す
        guard let email = emailTextField.text else { return }
        guard let password = passwordTextField.text else { return }
         //認証
        Auth.auth().createUser(withEmail: email, password: password){(res,err) in
            
            if let err = err{
                print("認証情報の保存に失敗しました\(err)")
                HUD.hide{ (_) in
                    HUD.flash(.error, delay: 1)
                }
                return
            }
            self.addUserInfoToFirestore(email: email)
        }
        
    }
    
    private func addUserInfoToFirestore(email: String){
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        guard let name = self.usernameTextField.text else {return}
        
        let docData = ["email": email, "name": name, "creatAt": Timestamp()] as [String : Any]
        let userRef =  Firestore.firestore().collection("users").document(uid)
        
            userRef.setData(docData){ (err) in
            if let err = err{
                print("Firestoreへの保存に失敗しました\(err)")
                HUD.hide{ (_) in
                    HUD.flash(.error, delay: 1)
                }
                return
            }
            print("Firestoreへの保存に成功しました")
                
            userRef.getDocument{ (snapshot, err) in
                if let err = err{
                    print("ユーザー情報の取得に失敗しました\(err)")
                    //アニメーションNGの時
                    HUD.hide{ (_) in
                        HUD.flash(.error, delay: 1)
                    }
                    return
                }
                
                guard let data = snapshot?.data() else {return}
                let user = User.init(dic: data)
                print("ユーザー情報の取得が出来ました。\(user.email)")
                //アニメーションOKの時
                HUD.hide{ (_) in
//                    HUD.flash(.success, delay: 1)
                    HUD.flash(.success, onView: self.view, delay: 1) { (_) in
                        self.presentToHomeViewController(user: user)
                    }
                }
            }
        }
    }
    
    private func presentToHomeViewController(user: User){
        //遷移
        let storyBoard = UIStoryboard(name: "Home", bundle: nil)
        let homeViewController = storyBoard.instantiateViewController(identifier: "HomeViewController") as HomeViewController
        homeViewController.user = user
        //画面をフルスクリーンにする
        homeViewController.modalPresentationStyle = .fullScreen
        self.present(homeViewController, animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        RegisterButton.isEnabled = false
        RegisterButton.backgroundColor = UIColor.rgb(red: 255, green: 165, blue: 167)
        RegisterButton.layer.cornerRadius = 10
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
        usernameTextField.delegate = self
        
        //キーボードが出た時のレスポンス
        NotificationCenter.default.addObserver(self, selector: #selector(showkeyboard), name: UIResponder.keyboardWillShowNotification, object: nil)
        //キーワードが隠れた時のレスポンス
        NotificationCenter.default.addObserver(self, selector: #selector(hidekeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.isHidden = true
    }
    @objc func showkeyboard(notification: Notification){
        /*1 キーボードのフレームのみを取得
        2 キーボードMinYの取得（上から見て一番低い位置）keyboardMinYはoptional型なのでguard letを使う
         値がnilなら処理を終わらせる
        3 RegisterのMaxYの取得（上から見て一番高い位置）
        4 差分だけ調整*/
        
        let keyboadFrame = (notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as AnyObject).cgRectValue
        
        guard let keyboardMinY = keyboadFrame?.minY else { return }
        let registerButtonMaxY = RegisterButton.frame.maxY
        let distance = registerButtonMaxY - keyboardMinY + 20
        let tranceform = CGAffineTransform(translationX: 0, y: -distance)
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [], animations: {
            self.view.transform = tranceform
        })
        
    }
    
    @objc func hidekeyboard(){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [], animations: {
            self.view.transform = .identity
        })
    }
        
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }

}


extension ViewController: UITextFieldDelegate{
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        //それぞれが空かどうか判定 nilだったらtrue返す
        let emailIsEmpty = emailTextField.text?.isEmpty ?? true
        let passwordIsEmpty = passwordTextField.text?.isEmpty ?? true
        let usernameIsEmpty = usernameTextField.text?.isEmpty ?? true
        //もし空ならRegisterButtonは使えない色を薄くする
        if emailIsEmpty || passwordIsEmpty || usernameIsEmpty{
            RegisterButton.isEnabled = false
            RegisterButton.backgroundColor = UIColor.rgb(red: 255, green: 165, blue: 167)
        } else {
            RegisterButton.isEnabled = true
            RegisterButton.backgroundColor = UIColor.rgb(red: 255, green: 0, blue: 0)
        }
    }
}

