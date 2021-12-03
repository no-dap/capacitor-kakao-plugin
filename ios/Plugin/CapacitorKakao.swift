import Foundation
import Capacitor

import KakaoSDKUser
import KakaoSDKCommon
import KakaoSDKLink
import KakaoSDKTemplate
import KakaoSDKAuth
import KakaoSDKTalk

extension Encodable {
    
    var toDictionary : [String: Any]? {
        guard let object = try? JSONEncoder().encode(self) else { return nil }
        guard let dictionary = try? JSONSerialization.jsonObject(with: object, options: []) as? [String:Any] else { return nil }
        return dictionary
    }
}

@objc public class CapacitorKakao: NSObject {
    @objc public func kakaoLogin(_ call: CAPPluginCall) -> Void {
        
        // 카카오톡 설치 여부 확인
        if (UserApi.isKakaoTalkLoginAvailable()) {
            UserApi.shared.loginWithKakaoTalk {(oauthToken, error) in
                if let error = error {
                    call.reject("error")
                }
                else {
                    call.resolve([
                        "value": oauthToken?.accessToken ?? ""
                    ])
                }
            }
        }
        else{
            
            UserApi.shared.loginWithKakaoAccount {(oauthToken, error) in
                    if let error = error {
                        print(error)
                        call.reject("error")
                    }
                    else {
                        call.resolve([
                            "value": oauthToken?.accessToken ?? ""
                        ])
                    }
                }
            
        }
    }
    
    @objc public func kakaoLogout(_ call: CAPPluginCall) -> Void {

        UserApi.shared.logout {(error) in
            if let error = error {
                print(error)
                call.reject("error")
            }
            else {

                call.resolve([
                    "value": "done"
                ])
            }
        }
    }
    
    
    
    @objc public func kakaoUnlink(_ call: CAPPluginCall) -> Void {

        UserApi.shared.unlink {(error) in
            if let error = error {
                print(error)
                call.reject("error")
            }
            else {

                call.resolve([
                    "value": "done"
                ])
            }
        }
    }
    
    
    @objc public func sendLinkFeed(_ call: CAPPluginCall) -> Void {

        let title = call.getString("title") ?? ""
        let description = call.getString("description") ?? ""
        let image_url = call.getString("imageUrl") ?? ""
        let image_link_url = call.getString("imageLinkUrl") ?? ""
        let button_title = call.getString("buttonTitle") ?? ""

        
        
        let link = Link(webUrl: URL(string:image_link_url),
                        mobileWebUrl: URL(string:image_link_url))

        let button = Button(title: button_title, link: link)
        let content = Content(title: title,
                                imageUrl: URL(string:image_url)!,
                                description: description,
                                link: link)
        let feedTemplate = FeedTemplate(content: content, social: nil, buttons: [button])

        //메시지 템플릿 encode
        if let feedTemplateJsonData = (try? SdkJSONEncoder.custom.encode(feedTemplate)) {

        //생성한 메시지 템플릿 객체를 jsonObject로 변환
            if let templateJsonObject = SdkUtils.toJsonObject(feedTemplateJsonData) {
                LinkApi.shared.defaultLink(templateObject:templateJsonObject) {(linkResult, error) in
                    if let error = error {
                        print(error)
                        call.reject("error")
                    }
                    else {

                        //do something
                        guard let linkResult = linkResult else { return }
                        UIApplication.shared.open(linkResult.url, options: [:], completionHandler: nil)
                        
                        call.resolve([
                            "value": "done"
                        ])
                    }
                }
            }
        }
    }

    @objc public func getUserInfo(_ call: CAPPluginCall) -> Void {
        UserApi.shared.me() {(user, error) in
            if let error = error {
                print(error)
                call.reject("me() failed.")
            }
            else {
                print("me() success.")
                call.resolve([
                    "value": user?.toDictionary as Any
                ])
            }
        }
    }

    @objc public func getFriendList(_ call: CAPPluginCall) -> Void {
        TalkApi.shared.friends {(friends, error) in
            if let error = error {
                print(error)
                call.reject("getFriendList() failed.")
            }
            else {
                print("getFriendList() success")
                let friendList = friends?.toDictionary
                call.resolve([
                    "value": (friendList != nil) ? friendList!["elements"] as Any : [] as Any
                ])
            }
        }
    }

    @objc public func loginWithNewScopes(_ call: CAPPluginCall) ->  Void {
        var scopes = [String]()
        guard let tobeAgreedScopes = call.getArray("scopes", String.self) else {
            call.reject("scopes failed")
            return
        }
        for scope in tobeAgreedScopes {
            scopes.append(scope)
        }
            
        if scopes.count == 0  { return }

        //필요한 scope으로 토큰갱신을 한다.
        UserApi.shared.loginWithKakaoAccount(scopes: scopes) { (_, error) in
            if let error = error {
                print(error)
            }
            else {
                UserApi.shared.me() { (user, error) in
                    if let error = error {
                        print(error)
                    }
                    else {
                        print("me() success.")

                        //do something
                        _ = user
                    }

                } //UserApi.shared.me()
            }

        }
    }

    @objc private func getUserScopes(_ call: CAPPluginCall) -> Any {
        UserApi.shared.scopes() { (scopeInfo, error) in
            if let error = error {
                self?.errorHandler(error: error)
                call.reject("get kakao user scope failed : ")
            }
            else {
                self?.success(scopeInfo)
                call.resolve([
                    "value": scopeInfo
                ])
            }
        }
    }
}
