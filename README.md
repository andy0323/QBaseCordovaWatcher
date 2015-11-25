# QBaseCordovaWatcher

Cordova的监察工具，简单的实现了所见即所得的效果。

## 依赖环境

1. 确认本机环境是否配置`nodejs环境`，如果没有安装，请自行安装。
2. 安装依赖包
	* 根目录执行`npm install`
	* server目录执行`npm install`

## 如何使用

### 启动流程

1. 客户端配置（可选）
	* 导入客户端插件
	* 配置xml.plist（如果你的项目发生）
2. 轻应用配置
	* 将已开发`www`替换到根目录下的`www`下
3. 服务启动
	* 执行`gulp`
	* 执行`gulp watch`

**注意：** 首次安装需要同步代码，执行`gulp update`

## TODO

1. 加入安卓端

## Q&A

### 为什么无法进行实时同步

1. 请确认手机与笔记本是否连接再同一个局域网下（可以正常通讯）。
2. 请确认所有服务已经启动

## Contact

**author:** Andy Jin  
**Email:** andy_ios@163.com

##Licenses

All source code is licensed under the [MIT License](https://github.com/andy0323/QBaseLanguage/blob/master/LICENSE).