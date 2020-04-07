//
//  LoginViewController.swift
//  LoginWithFirebase
//
//  Created by 柿沼儀揚 on 2020/03/26.
//  Copyright © 2020 柿沼儀揚. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import AuthenticationServices
import PKHUD

class LoginViewController: UIViewController {
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var LoginButton: UIButton!
    @IBOutlet weak var dontHaveAccountButton: UIButton!
    //前の画面に戻る
    
    @IBAction func tappedDontHaveAccountButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func tappedLoginButton(_ sender: Any) {
        HUD.show(.progress, onView: self.view)
        print("tapped Button")
        
        guard  let email = emailTextField.text else { return }
        guard let password = passwordTextField.text else { return }
        
        Auth.auth().signIn(withEmail: email, password: password) { (res, err) in
            if let err = err {
                print("ログイン情報の取得に失敗しました: ", err)
                return
            }
            print("ログインに成功しました")
    
            guard let uid = Auth.auth().currentUser?.uid else { return }
            let userRef =  Firestore.firestore().collection("users").document(uid)
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
        
        LoginButton.layer.cornerRadius = 10
        LoginButton.isEnabled = false
        LoginButton.backgroundColor = UIColor.rgb(red: 255, green: 165, blue: 167)
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
    }
}

// MARK: - UITextFieldDelegate
extension LoginViewController: UITextFieldDelegate {
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        //それぞれが空かどうか判定 nilだったらtrue返す
        let emailIsEmpty = emailTextField.text?.isEmpty ?? true
        let passwordIsEmpty = passwordTextField.text?.isEmpty ?? true
        //もし空ならRegisterButtonは使えない色を薄くする
        if emailIsEmpty || passwordIsEmpty{
            LoginButton.isEnabled = false
            LoginButton.backgroundColor = UIColor.rgb(red: 255, green: 165, blue: 167)
        } else {
            LoginButton.isEnabled = true
            LoginButton.backgroundColor = UIColor.rgb(red: 255, green: 0, blue: 0)
        }
    }
}
