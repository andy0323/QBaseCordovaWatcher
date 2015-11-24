require('shelljs/global');
var gulp = require('gulp');

var fs = require('fs');
var os = require('os'); 
var path = require('path');
var dgram = require("dgram");
var socket = dgram.createSocket("udp4");

const WWW_PATH = __dirname + '/www';
const SOCKET_PORT = 30012;

const DOWNLOAD_SERVER_PATH = __dirname + '/server'
const DOWNLOAD_SERVER_PORT = 3012;
const DOWNLOAD_SERVER_URL = '/www_zip/www.zip';

var IPv4 = getIPv4();

gulp.task('default', function() {
	// 启动下载服务
	exec('node ' + DOWNLOAD_SERVER_PATH + '/bin/www')
});

gulp.task('watch', function () {
	// 判断指定的www文件夹是否存在
	var isExists = fs.existsSync(WWW_PATH);
	if (!isExists) {
		console.log('ERROR：' + WWW_PATH + '不存在');
	};
  
  // 绑定广播
  socket.bind(function () {
  	socket.setBroadcast(true);
	});

  // WWW目录的监控
  gulp.watch('www/**',   fileChangedCallback);
});

gulp.task('update', function() {
	// 更新服务端最新安装包
	var zipPath = DOWNLOAD_SERVER_PATH + '/public/www_zip/www.zip';
	// 移除旧的Zip包
	exec('rm -rf ' + zipPath);
	// 压缩最新的Zip包
	cd(WWW_PATH);
	exec('zip -r ' + zipPath + ' .');


	// 通知客户端更新
	var downloadURL = 'http://' + IPv4 + ':' + DOWNLOAD_SERVER_PORT + DOWNLOAD_SERVER_URL;
	var body = {
		'event': 'update',
		'url'  : downloadURL
	};
	messageSend(body);
});

/**
 *	文件发生变化回调
 */
function fileChangedCallback(event) {

console.log('a');

	return;
	var filePath = event.path;	

	// 获取文件相对路径
	var relativePath = path.relative(WWW_PATH, filePath);

	// 判断是否为删除操作
	var isExists = fs.existsSync(filePath);
	if (!isExists) {
		var body = {
			'event'  : 'watch',
  		'exists' : 0,
  		'path'   : relativePath,
  		'content': null
  	};
		messageSend(body);
		return;
	};

	// 如果文件更新（添加、或者更新）
	fs.readFile(filePath, 'utf-8', function (err, data) {
  	if (err) throw err;

  	var body = {
  		'event'  : 'watch',
  		'exists' : 1,
  		'path'   : relativePath,
  		'content': data
  	};
		messageSend(body);
	});
}

/** 发送消息至客户端 */
function messageSend(messageObj) {
	var message = new Buffer(JSON.stringify(messageObj));
	socket.send(message, 0, message.length, SOCKET_PORT, IPv4, function(err, bytes) {
		if (err) {
			console.log('update error');
		}else {
			console.log('update succ');			
		}
	});
}

/**
 * 获取本地局域网IP
 */
function getIPv4() {
	var IPv4;
	for(var i = 0; i < os.networkInterfaces().en0.length; i++) {   
		if(os.networkInterfaces().en0[i].family == 'IPv4') {  
    	IPv4 = os.networkInterfaces().en0[i].address;  
		}
	}  
	return IPv4;
}
