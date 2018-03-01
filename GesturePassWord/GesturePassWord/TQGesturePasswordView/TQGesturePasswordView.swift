//
//  TQGesturePasswordView.swift
//  PingAnTong_WenZhou
//
//  Created by 胡志辉 on 2018/1/5.
//  Copyright © 2018年 maomao. All rights reserved.
//



/**
 说明
 1.在初始化的时候，需要传入一个类型，来判断是设置密码还是用于登录
 属性为 _gesturePassWordType，可选类型有set(设置密码) login(用于登录) forget(忘记密码的时候进行设置，处理方式和set一致，就是底部按钮样式不一样)
 */




import UIKit

fileprivate let kSCREEN_WIDTH = UIScreen.main.bounds.size.width
fileprivate let kSCREEN_HEIGHT  = UIScreen.main.bounds.size.height
/* 是否为iPhone X */
fileprivate let isIphoneX = kSCREEN_HEIGHT == 812 ? true : false
fileprivate let KHighlighColor :String = "#00ABE3"

private let ButtonWidth : CGFloat = 40
private let ButtonColNum : NSInteger = 3
private let ButtonSpace : CGFloat = (kSCREEN_WIDTH - CGFloat(ButtonColNum) * ButtonWidth) / 4

public enum TQGesturePasswordType : Int {
    case set = 1//设置密码
    case login//登录
    case forget//忘记密码进入
}

public enum TQGesturePasswordBtnType : Int {
    case cancleSet = 0//取消设置
    case forgetPwd //忘记密码
    case changeLogin // 切换登录方式
    case skipSet//跳过设置
}

enum TQGesturePasswordStatus:Int {
    case success = 0  //成功
    case lessThenFour = 1//设置密码的时候密码长度小于4
    case diffrent = 2//设置密码的时候密码不一致
    case firstSetSuccess = 3//第一次设置密码成功的时候
    case error = 4//登录错误
}

class TQGestureButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setUpView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setUpView()
    }
    
    func setUpView(){
        self.layer.cornerRadius = self.width * 0.5
        self.layer.masksToBounds = true
        self.isUserInteractionEnabled = false
        self.backgroundColor = UIColor(hex: "#b4b4b4")
    }
    
}

class TQGesturePasswordView: UIView {
    //旧密码
   fileprivate var _oldPassWord : String?
    var oldePassWord : String?{
        set{
            _oldPassWord = newValue
            self.strokePwdView.olderPassWord = _oldPassWord
        }
        get{
            return _oldPassWord
        }
    }
    
    
    
    //保存已经路过的点
    var pointsArr = [CGPoint]()
    //当前手指所在的点
    var fingurePoint:CGPoint!
    //保存当前绘画的密码
    var passwordArr : [Int] = [Int]()
    
    //登录的时候，计算错误的次数
    var errorTimes : Int = 0
    
    
    var _gesturePassWordType : TQGesturePasswordType? = TQGesturePasswordType.login
    var gesturePassWordType : TQGesturePasswordType?{
        get{
            return _gesturePassWordType
        }
        set(newValue){
            _gesturePassWordType = newValue
            self.strokePwdView.type = (_gesturePassWordType?.rawValue)!
            if _gesturePassWordType == TQGesturePasswordType.set {
                //按钮显隐
                self.cancelSetBtn.isHidden = false
                self.forgetPwdBtn.isHidden = true
                self.changeLoginBtn.isHidden = true
                self.skipSetBtn.isHidden = true
                //headerView的显隐
                self.loginHeaderView.isHidden = true
                self.setPwdHeaderView.isHidden = false
            }
            if _gesturePassWordType == TQGesturePasswordType.login {
                self.cancelSetBtn.isHidden = true
                self.forgetPwdBtn.isHidden = false
                self.changeLoginBtn.isHidden = false
                self.skipSetBtn.isHidden = true
                //headerView的显隐
                self.loginHeaderView.isHidden = false
                self.setPwdHeaderView.isHidden = true
            }
            if _gesturePassWordType == TQGesturePasswordType.forget {
                self.cancelSetBtn.isHidden = true
                self.forgetPwdBtn.isHidden = true
                self.changeLoginBtn.isHidden = true
                self.skipSetBtn.isHidden = false
                //headerView的显隐
                self.loginHeaderView.isHidden = true
                self.setPwdHeaderView.isHidden = false
            }
        }
    }
    
    var strokePwdView = TQStrokePasswordView()
    var setPwdHeaderView = TQGesturePasswordSetView()
    var loginHeaderView = TQGesturePasswordLoginView()
    
    var cancelSetBtn = UIButton()
    var forgetPwdBtn = UIButton()
    var changeLoginBtn = UIButton()
    var skipSetBtn = UIButton()
    
    
    
    
    //成功的回调
    var gesturePasswordSuccessCallBack : ((_ password:String,_ type:TQGesturePasswordType)->())?
    
    //点击按钮的回调
    var gesturePasswordClickBtnCallBack:((_ btnType:TQGesturePasswordBtnType)->())?
    
    
    //手势密码字符串获取
    var passWord : String {
        get{
            var str = ""
            for p in passwordArr {
                str.append(String(p))
            }
            return str
            
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }

}
//布局
extension TQGesturePasswordView{
    //初始化
    func setup(){
        self.backgroundColor = UIColor.white
        self.strokePasswordCallBack()
        //初始化底部按钮
        //1.设置密码的情况下，只有右边一个取消设置按钮
        self.addSubview(self.cancelSetBtn)
        self.cancelSetBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14.0)
        self.cancelSetBtn.setTitle("取消设置", for: UIControlState.normal)
        self.cancelSetBtn.setTitleColor(UIColor(hex:"#505050"), for: UIControlState.normal)
        self.cancelSetBtn.addTarget(self, action: #selector(TQGesturePasswordView.cancelSetBtnClick(sender:)), for: UIControlEvents.touchUpInside)
        self.cancelSetBtn.snp.makeConstraints { (make) in
            make.right.equalTo(-10)
            make.width.equalTo(75)
            make.height.equalTo(40)
            make.bottom.equalTo((isIphoneX ? -34.0 : 0))
        }
        //2.登录密码情况下，有两遍两个按钮
        self.addSubview(self.forgetPwdBtn)
        self.forgetPwdBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14.0)
        self.forgetPwdBtn.setTitle("忘记手势密码", for: UIControlState.normal)
        self.forgetPwdBtn.setTitleColor(UIColor(hex:"#505050"), for: UIControlState.normal)
        self.forgetPwdBtn.addTarget(self, action: #selector(TQGesturePasswordView.forgetPassWordBtnClick(sender:)), for: UIControlEvents.touchUpInside)
        self.forgetPwdBtn.snp.makeConstraints { (make) in
            make.left.equalTo(10)
            make.bottom.equalTo((isIphoneX ? -34.0 : 0))
            make.width.equalTo(90)
            make.height.equalTo(40)
        }
        
        self.addSubview(self.changeLoginBtn)
        self.changeLoginBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14.0)
        self.changeLoginBtn.setTitle("切换登录方式", for: UIControlState.normal)
        self.changeLoginBtn.setTitleColor(UIColor(hex:"#505050"), for: UIControlState.normal)
        self.changeLoginBtn.addTarget(self, action: #selector(TQGesturePasswordView.changeLoginBtnClick(sender:)), for: UIControlEvents.touchUpInside)
        self.changeLoginBtn.snp.makeConstraints { (make) in
            make.right.equalTo(-10)
            make.bottom.equalTo((isIphoneX ? -34.0 : 0))
            make.height.equalTo(40)
            make.width.equalTo(90)
        }
        
        //3.跳过设置按钮
        self.addSubview(self.skipSetBtn)
        self.skipSetBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14.0)
        self.skipSetBtn.setTitle("跳过设置", for: UIControlState.normal)
        self.skipSetBtn.setTitleColor(UIColor(hex:"#505050"), for: UIControlState.normal)
        self.skipSetBtn.addTarget(self, action: #selector(TQGesturePasswordView.skipSetBtnClick(sender:)), for: UIControlEvents.touchUpInside)
        self.skipSetBtn.snp.makeConstraints { (make) in
            make.right.equalTo(-10)
            make.width.equalTo(75)
            make.height.equalTo(40)
            make.bottom.equalTo((isIphoneX ? -34.0 : 0))
        }
        
        self.cancelSetBtn.isHidden = false
        self.changeLoginBtn.isHidden = false
        self.forgetPwdBtn.isHidden = false
        self.skipSetBtn.isHidden = false
        
        //初始化描绘密码视图
        self.addSubview(self.strokePwdView)
        let height = ButtonSpace * 3 + ButtonWidth * 3
        self.strokePwdView.snp.makeConstraints { (make) in
            make.left.right.equalTo(0)
            make.height.equalTo(height)
            make.bottom.equalTo((isIphoneX ? -100.0 : -60.0))
        }
        //设置密码头部视图
        self.addSubview(self.setPwdHeaderView)
        self.setPwdHeaderView.snp.makeConstraints { (make) in
            make.bottom.equalTo(self.strokePwdView.snp.top)
            make.top.left.right.equalTo(0)
        }
        //登录时的上部分视图
        self.addSubview(self.loginHeaderView)
        self.loginHeaderView.snp.makeConstraints { (make) in
            make.bottom.equalTo(self.strokePwdView.snp.top)
            make.left.top.right.equalTo(0)
        }
        
        //默认按钮显示
        self.cancelSetBtn.isHidden = true
        self.forgetPwdBtn.isHidden = false
        self.changeLoginBtn.isHidden = false
        self.skipSetBtn.isHidden = true
        //headerView的显隐
        self.loginHeaderView.isHidden = false
        self.setPwdHeaderView.isHidden = true
    }
}
//回调
extension TQGesturePasswordView{
    func strokePasswordCallBack() {
        self.strokePwdView.strokePassWordCallBack = {(status,pwd)->() in
           print(status,pwd)
            switch status {
            case TQGesturePasswordStatus.lessThenFour:
                    self.setPwdHeaderView.updateView(passWord: pwd, message: "至少连接4个点，请重试")
                break
            case TQGesturePasswordStatus.firstSetSuccess:
                self.setPwdHeaderView.updateView(passWord: pwd, message: "再次设置手势密码")
                break
            case TQGesturePasswordStatus.diffrent:
                self.setPwdHeaderView.updateView(passWord: "", message: "您第二次输入的手势密码与第一次的不同，请重新设置")
                break
            case TQGesturePasswordStatus.error:
                //登录时密码错误,需要计算次数
                self.errorTimes = self.errorTimes + 1
                if self.errorTimes == 5 {
                    self.dismiss()
                }else{
                    let str = NSString(format: "你已经输入%@次错误的手势密码，错误输入5次后将使用密码登录", String(self.errorTimes))
                    self.loginHeaderView.updateView(msg: str as String, color: UIColor.red)
                }
                
                break
            case TQGesturePasswordStatus.success:
                //成功,有设置密码成功和登录成功
//                if self.gesturePassWordType == TQGesturePasswordType.set {
//
//                }
//                if self.gesturePassWordType == TQGesturePasswordType.login {
//
//                }
                if self.gesturePasswordSuccessCallBack != nil {
                    self.gesturePasswordSuccessCallBack!(pwd,self.gesturePassWordType!)
                }
                self.dismiss()
                
                break
                
            default:
                break
            }
        }
    }
    
    //按钮方法回调
    //1.取消设置
    @objc func cancelSetBtnClick(sender:UIButton){
        self.dismiss()
    }
    //2.忘记密码
    @objc func forgetPassWordBtnClick(sender:UIButton){
        self.dismiss()
        if self.gesturePasswordClickBtnCallBack != nil {
            self.gesturePasswordClickBtnCallBack!(TQGesturePasswordBtnType.forgetPwd)
        }
    }
    //3.切换登录方式
    @objc func changeLoginBtnClick(sender:UIButton){
        self.dismiss()
        if self.gesturePasswordClickBtnCallBack != nil {
            self.gesturePasswordClickBtnCallBack!(TQGesturePasswordBtnType.changeLogin)
        }
    }
    //4.跳过设置
    @objc func skipSetBtnClick(sender:UIButton){
        self.dismiss()
        if self.gesturePasswordClickBtnCallBack != nil {
            self.gesturePasswordClickBtnCallBack!(TQGesturePasswordBtnType.cancleSet)
        }
    }
}

//出现 消失方法
extension TQGesturePasswordView{
    public func show(){
        let window:UIWindow? = (UIApplication.shared.delegate?.window)!
        if window != nil {
            window?.addSubview(self)
            self.snp.makeConstraints({ (make) in
                make.edges.equalTo(window!)
            })
        }
    }
    public func dismiss(){
        self.removeFromSuperview()
    }
}

//Mark:绘制密码视图
class TQStrokePasswordView: UIView {
    
    var olderPassWord : String?
    
    
    //路劲
    var path:UIBezierPath =  UIBezierPath()
    //类型
    var type : TQGesturePasswordType.RawValue = 2
    //保存经过的点
    var pointsArr :[CGPoint] = [CGPoint]()
    
    //当前手指所在的点
    var fingurePoint:CGPoint!
    //保存当前绘画的密码
    var passwordArr : [Int] = [Int]()
    //设置密码的时候，保存的是第一次设置的密码
    var setPwdAry:[Int] = [Int]()
    
    
    //设置密码的次数
    var setPwdTimes : Int = 0
    
    
    //密码绘制完成的回调
    var strokePassWordCallBack : ((_ status:TQGesturePasswordStatus,_ passwordStr:String)->())?
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setUp()
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    convenience init(frame:CGRect,type:TQGesturePasswordType) {
        self.init(frame: frame)
        self.type = type.rawValue
        self.setUp()
    }
}
//布局
extension TQStrokePasswordView{
    func setUp() {
        self.backgroundColor = UIColor.white
        // TODO: 创建视图
        let colNum = ButtonColNum
        var col = 0,row = 0
        
        let width:CGFloat = ButtonWidth
        let height:CGFloat = width
        
        var x:CGFloat = 0
        var y:CGFloat = 0
        
        
        /// 计算空隙
        let space = ButtonSpace
        
        for index in 0..<9{
            //计算当前所在行
            col = index % colNum
            row = index / colNum
            //计算坐标
            x = CGFloat(col) * width + CGFloat(col + 1) * space
            y = CGFloat(row) * width + CGFloat(row) * space
            let button = TQGestureButton(frame: CGRect(x: x, y: y, width: width, height: height))
            
            button.tag = index
            
            self.addSubview(button)
        }
        //MARK: 初始化路径
        self.path.lineWidth = 5
        self.path.lineCapStyle = .round
        self.path.lineJoinStyle = .round
    }
}

//代理 业务
extension TQStrokePasswordView{
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        //每次点击移除所有存储过的点，重新统计
        self.passwordArr.removeAll()
        self.pointsArr.removeAll()
        self.setNeedsDisplay()
        self.fingurePoint = CGPoint.zero
        //清除所有按钮的选中状态
        for button in self.subviews{
            
            if button.isKind(of: TQGestureButton.self) {
                
                button.backgroundColor  =  UIColor(hex: "#B4B4B4")
                
            }
            
        }
        self.touchChanged(touch: touches.first!)
    }
    
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        self.touchChanged(touch: touches.first!)
    }
    
    //MARK: 触摸变化时的方法
    func touchChanged(touch:UITouch){
        let point = touch.location(in: self)
        
        self.fingurePoint = point
        
        for button in self.subviews{
            
            if button.isKind(of: TQGestureButton.self) && !self.pointsArr.contains(button.center) && button.frame.contains(point){
                
//                记录已经走过的点
                if (self.type == TQGesturePasswordType.set.rawValue || self.type == TQGesturePasswordType.forget.rawValue) && self.setPwdTimes == 0{
                    self.setPwdAry.append(button.tag)
                }else{
                    self.passwordArr.append(button.tag)
                }
                
//                记录密码
                self.pointsArr.append(button.center)
//                设置按钮的背景色为红色
                button.backgroundColor  =  UIColor(hex: KHighlighColor)
            }
            
        }
        //会调用draw 方法
        self.setNeedsDisplay()
    }
    
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        //根据绘画的密码判断是否正确
        //1.在登录情况下，只需判断绘画的密码是否正确
        //2.在设置的情况下，需判断绘画密码的长度大于4，小于4，则提示，第二次设置密码的时候要判断两次密码是否一致，不一致重新设置
        self.strokePassWordComplete()
    }
    
    //对各种情况进行判断，回调
   fileprivate func strokePassWordComplete(){
        switch self.type {
        case TQGesturePasswordType.set.rawValue:
            self.setGesturePwd()
            break
        case TQGesturePasswordType.forget.rawValue:
            self.setGesturePwd()
            break
        case TQGesturePasswordType.login.rawValue: do {
            //登录的时候,判断本地的手势密码和描绘的是否一样
            var str = ""
            for p in self.passwordArr {
                str.append(String(p))
            }
            let oldPwd = self.olderPassWord != nil ? self.olderPassWord : ""
            if oldPwd == str {
                //描绘的密码和保存的一致，成功
                if self.strokePassWordCallBack != nil {
                self.strokePassWordCallBack!(TQGesturePasswordStatus.success,str)
                }
            }else{
                if !str.isEmpty {
                    if self.strokePassWordCallBack != nil {
                        self.strokePassWordCallBack!(TQGesturePasswordStatus.error,str)
                    }
                }
                self.updateView()
            }
            
        }
            break
        default:
            break
        }
    }
    
    //设置密码或者忘记密码设置时的操作
    fileprivate func setGesturePwd(){
        //设置密码的时候
        if self.setPwdTimes == 0{
            //第一次设置密码，判断长度
            if self.setPwdAry.count < 4 {
                if self.strokePassWordCallBack != nil {
                    self.strokePassWordCallBack!(TQGesturePasswordStatus.lessThenFour,"")
                }
                self.setPwdAry.removeAll()
                self.updateView()
            }else{
                var str = ""
                for p in self.setPwdAry {
                    str.append(String(p))
                }
                if self.strokePassWordCallBack != nil {
                    self.strokePassWordCallBack!(TQGesturePasswordStatus.firstSetSuccess,str)
                }
                self.setPwdTimes = 1
                self.updateView()
            }
        }else{
            //再次设置密码，判断两次密码是否一致
            var firstPwd = ""
            var secondPwd = ""
            for p in self.setPwdAry {
                firstPwd.append(String(p))
            }
            for p in self.passwordArr {
                secondPwd.append(String(p))
            }
            if firstPwd == secondPwd {
                //设置成功,成功回调
//                let userName = UserInfoViewModel.shared.getUserInfoWithNearlyUser().0
//                let password = UserInfoViewModel.shared.getUserInfoWithNearlyUser().1
//                UserInfoViewModel.shared.insertUserInfo(userName: userName, passWord: password, gesturePassword: secondPwd)
                if self.strokePassWordCallBack != nil {
                    self.strokePassWordCallBack!(TQGesturePasswordStatus.success,secondPwd)
                }
            }else{
                //密码不一致的时候，清空保存第一次设置的密码
                if self.strokePassWordCallBack != nil {
                    self.strokePassWordCallBack!(TQGesturePasswordStatus.diffrent,secondPwd)
                }
                self.setPwdAry.removeAll()
                self.updateView()
            }
            self.setPwdTimes = 0
        }

    }
    
    func updateView() {
//        每次点击移除所有存储过的点，重新统计
        self.passwordArr.removeAll()
        self.pointsArr.removeAll()
        self.setNeedsDisplay()
        self.fingurePoint = CGPoint.zero
            //清除所有按钮的选中状态
        for button in self.subviews{
            if button.isKind(of: TQGestureButton.self) {
                button.backgroundColor  =  UIColor(hex: "#B4B4B4")
            }
            }
    }
    
    //MARK: 绘制
    override func draw(_ rect: CGRect) {
        self.path.removeAllPoints()
        for (index,point) in self.pointsArr.enumerated(){

            if index == 0{
                self.path.move(to: point)
            }else{
                self.path.addLine(to: point)
            }

        }
        //让画线跟随手指
        if self.fingurePoint != CGPoint.zero && self.pointsArr.count > 0{
            self.path.addLine(to: self.fingurePoint)
        }
        UIColor(hex: KHighlighColor).setStroke()
        self.path.stroke()
    }
    
    func show(){
        let window:UIWindow? = (UIApplication.shared.delegate?.window)!
        if window != nil {
            window?.addSubview(self)
            self.snp.makeConstraints({ (make) in
                make.left.equalTo(10)
                make.right.equalTo(-10)
                make.bottom.equalTo(isIphoneX ? 64 : 30)
                make.height.equalTo( ButtonSpace * 3 + ButtonWidth * 3 )
            })
        }
    }
    func disMiss(){
        self.removeFromSuperview()
    }
}

/****************0----------------------------------------***********/

//Mark:登录时，header显示的视图
class TQGesturePasswordLoginView: UIView {
    var deslab = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setUpView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setUpView()
    }
}
//布局
extension TQGesturePasswordLoginView{
    func setUpView(){
        //self的设置
        self.backgroundColor = UIColor.white
        //deslabel
        self.addSubview(self.deslab)
        self.deslab.text = "请输入手势密码"
        self.deslab.numberOfLines = 2
        self.deslab.textAlignment = NSTextAlignment.center
        self.deslab.font = UIFont.systemFont(ofSize: 14.0)
        self.deslab.snp.makeConstraints { (make) in
            make.left.equalTo(10)
            make.bottom.equalTo(-10)
            make.right.equalTo(-10)
            make.height.equalTo(40)
        }
        
        //头像img
        let img = UIImageView(image: UIImage(named: "login_gesture_header"))
        self.addSubview(img)
        img.snp.makeConstraints { (make) in
            make.width.height.equalTo(70)
            make.centerX.equalTo(self)
            make.bottom.equalTo(self.deslab.snp.top).offset(-30)
        }
        
        //版本信息
        let versionLab = UILabel()
        versionLab.text = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String
        versionLab.font = UIFont.systemFont(ofSize: 14.0)
        versionLab.textColor = UIColor(hex: "#505050")
        self.addSubview(versionLab)
        versionLab.snp.makeConstraints { (make) in
            make.left.equalTo(img.snp.right)
            make.top.equalTo(img.snp.centerY)
            make.height.equalTo(20)
        }
        
        
    }
    //更新布局
    func updateView(msg:String,color:UIColor) {
        self.deslab.text = msg
        self.deslab.textColor = color
    }
}


/************************************---------------------*************/
//Mark:设置时，header显示的视图
class TQGesturePasswordSetView: UIView {
    var desLab = UILabel()
    var boxView = SmallBoxView()
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setUp()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setUp()
    }
}
//布局
extension TQGesturePasswordSetView{
    func setUp() {
        
        //描述lab
        self.desLab.font = UIFont.systemFont(ofSize: 14.0)
        self.desLab.numberOfLines = 2
        self.desLab.textAlignment = NSTextAlignment.center
        self.addSubview(self.desLab)
        self.desLab.text = "绘制解锁图案"
        self.desLab.snp.makeConstraints { (make) in
            make.left.equalTo(10)
            make.right.equalTo(-10)
            make.bottom.equalTo(-10)
            make.height.equalTo(40)
        }
        
        self.addSubview(boxView)
        boxView.snp.makeConstraints { (make) in
            make.bottom.equalTo(self.desLab.snp.top)
            make.centerX.equalTo(self)
            make.width.height.equalTo(100)
        }
        
        let titleLab = UILabel()
        titleLab.font = UIFont.systemFont(ofSize: 14.0)
        titleLab.textColor = UIColor(hex: "#505050")
        titleLab.text = "设置手势密码"
        self.addSubview(titleLab)
        titleLab.snp.makeConstraints { (make) in
            make.bottom.equalTo(self.boxView.snp.top).offset(-10)
            make.centerX.equalTo(self)
            make.height.equalTo(20)
        }
        
    }
}
//逻辑
extension TQGesturePasswordSetView{
    //更新界面，就是在第一次设置密码成功后，更新界面
    func updateView(passWord:String,message:String){
        self.desLab.text = message
        self.boxView.updateView(password: passWord)
    }
}

//小型九宫格
class SmallBoxView: UIView {
    //路劲
    var path = UIBezierPath()
    var pointsAry:[CGPoint] = [CGPoint]()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setUp()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setUp()
    }
    
    //初始化
    func setUp(){
        self.backgroundColor = UIColor.white
        // TODO: 创建视图
        var col = 0,row = 0
        
        let width:CGFloat = 20
        let height:CGFloat = width
        
        var x:CGFloat = 0
        var y:CGFloat = 0
        
        
        /// 计算空隙
        let space = (100 - width * 3)/2
        
        for i in 0..<9 {
            //计算当前所在行
            col = i % 3
            row = i / 3
            //计算坐标
            x = CGFloat(col) * width + CGFloat(col) * space
            y = CGFloat(row) * width + CGFloat(row) * space
            let lab = UILabel(frame: CGRect(x: x, y: y, width: width, height: height))
            lab.tag = i
            lab.layer.cornerRadius = width * 0.5
            lab.layer.masksToBounds = true
            lab.backgroundColor = UIColor(hex: "#b4b4b4")
            self.addSubview(lab)
        }
        self.path.lineWidth = 2
        self.path.lineCapStyle = .round
        self.path.lineJoinStyle = .round
    }
    
    //更新视图
    func updateView(password:String){
        
        //先对lab进行全部重置
        for lab in self.subviews {
            if lab.isKind(of: UILabel.self){
                lab.backgroundColor = UIColor(hex: "#b4b4b4")
            }
        }
        //遍历字符串，匹配lab，然后绘图
        self.pointsAry.removeAll()
        for i in password {
            for lab in self.subviews {
                if lab.isKind(of: UILabel.self) && String(i) == String(lab.tag){
                    lab.backgroundColor = UIColor(hex: KHighlighColor)
                    self.pointsAry.append(lab.center)
                }
            }
        }
        self.setNeedsDisplay()
    }
    //绘制
    override func draw(_ rect: CGRect) {
        self.path.removeAllPoints()
        for (index,point) in self.pointsAry.enumerated(){
            
            if index == 0{
                self.path.move(to: point)
            }else{
                self.path.addLine(to: point)
            }
        }
        UIColor(hex: KHighlighColor).setStroke()
        self.path.stroke()
    }
}

//Mark:-直接获取view的size，origin，x，y，width，height

extension UIView{
    
    var size:CGSize {
        get{
            return self.frame.size
        }
        set{
            self.frame.size = newValue
        }
    }
    
    var origin: CGPoint {
        get{
            return self.frame.origin
        }
        set{
            self.frame.origin = newValue
        }
    }
    
    
    var width:CGFloat{
        get{
            return self.size.width
        }
        set{
            self.size.width = newValue
        }
    }
    
    var height:CGFloat{
        get{
            return self.size.height
        }
        set{
            self.size.height = newValue
        }
    }
    
    var x:CGFloat{
        get{
            return self.origin.x
        }
        set{
            self.origin.x = newValue
        }
    }
    
    var y:CGFloat{
        get{
            return self.origin.y
        }
        set{
            self.origin.y = newValue
        }
    }
}



extension UIColor{
    
    convenience init(hex string: String) {
        var hex = string.hasPrefix("#")
            ? String(string.dropFirst())
            : string
        guard hex.count == 3 || hex.count == 6
            else {
                self.init(white: 1.0, alpha: 0.0)
                return
        }
        if hex.count == 3 {
            for (index, char) in hex.enumerated() {
                hex.insert(char, at: hex.index(hex.startIndex, offsetBy: index * 2))
            }
        }
        
        self.init(
            red:   CGFloat((Int(hex, radix: 16)! >> 16) & 0xFF) / 255.0,
            green: CGFloat((Int(hex, radix: 16)! >> 8) & 0xFF) / 255.0,
            blue:  CGFloat((Int(hex, radix: 16)!) & 0xFF) / 255.0, alpha: 1.0)
    }
}
