# GesturePassWord
# 示例图

![Image text](https://raw.githubusercontent.com/wode0weiyi/Image_Folder/master/手势密码示例图/手势密码示例.gif)

#使用方法
 1.第一种是有头部视图的使用
 
 //带头部视图的手势密码界面
 
    @IBAction func loginBtnClick(_ sender: UIButton) {
        let view = TQGesturePasswordView()
        //设置手势密码的作用，有三种情况
        /*
         public enum TQGesturePasswordType : Int {
         case set = 1//设置密码
         case login//登录
         case forget//忘记密码设置手势密码
         }
         */
        view.gesturePassWordType = TQGesturePasswordType.login
        //登录的情况下，需要传入旧密码,这里指的是旧的手势密码，不是登录密码
        view.oldePassWord = "0123"
        
        view.gesturePasswordSuccessCallBack = {[weak self](passWord,type) in
        //手势密码绘制完成的回调
            self?.passWordLab.text = passWord
        }
        view.gesturePasswordClickBtnCallBack = {[weak self](buttonType) in
        //点击回调，有四种情况
            /*
             public enum TQGesturePasswordBtnType : Int {
             case cancleSet = 0//取消设置
             case forgetPwd //忘记密码
             case changeLogin // 切换登录方式
             case skipSet//跳过设置
             }
             */
            
        }
        view.show()
        
    }
    
    
 2.第二种是不带头部视图的，不推荐使用，使用需要自己做逻辑处理
 
 //不带头部视图的手势密码界面
 
    @IBAction func loginBtnWithoutHeadBtnClick(_ sender: Any) {
        let view = TQStrokePasswordView()
        //设置手势密码登录的做用。三种情况
       /*
         public enum TQGesturePasswordType : Int {
            case set = 1//设置密码
            case login//登录
            case forget//忘记密码设置手势密码
        }
         */
        view.type = TQGesturePasswordType.login.rawValue
        //登录的时候，要设置旧密码
        view.olderPassWord = "0125"
        /*
         绘制成功的回调，type有三种类型
         1.TQGesturePasswordStatus.success成功
         2.TQGesturePasswordStatus.diffrent两次密码不一致（设置密码的时候）
         3.TQGesturePasswordStatus.error 错误
         4.TQGesturePasswordStatus.firstSetSuccess  第一次设置成功
         5.TQGesturePasswordStatus.lessThenFour  少于四位
         **/
        
        view.strokePassWordCallBack = {[weak self](type,passWord) in
            if type == TQGesturePasswordStatus.success {
                view.disMiss()
            }
            self?.passWordLab.text = passWord
        }
        view.show()
    }
    
 大家有什么不懂或者问题请call我，谢谢
