var gulp = require('gulp');

var fs = require('fs');
var os = require('os'); 
var path = require('path');
var dgram = require("dgram");
var socket = dgram.createSocket("udp4");

const WWW_PATH = __dirname + '/www';
const SOCKET_PORT = 30012;

var IPv4 = getIPv4();

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
  gulp.watch('www/*',   fileChangedCallback);
 	gulp.watch('www/*/*', fileChangedCallback);
});

/**
 *	文件发生变化回调
 */
function fileChangedCallback(event) {
	var filePath = event.path;
	var relativePath = path.relative(WWW_PATH, filePath);

	fs.readFile(filePath, 'utf-8', function (err, data) {
  	if (err) throw err;

  	var body = {
  		'path'   : relativePath,
  		'content': data
  	};

  	var message = new Buffer(JSON.stringify(body));
		socket.send(message, 0, message.length, SOCKET_PORT, IPv4, function(err, bytes) {
			if (err) {
				console.log('update error');
			}
		});
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
