var notifyUser = {};
dispatcher = new WebSocketRails(window.location.origin.split("//")[1] + "/websocket");


handleNew = function(response) {
	debugger;
	console.log(response);
};

var channel = dispatcher.subscribe('notify_user');


channel.bind('new_notification', handleNew);

notifyUser.dispatcher = dispatcher;
notifyUser.handleNew = handleNew;
window.notifyUser = notifyUser;