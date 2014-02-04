var notifyUser = {};
dispatcher = new WebSocketRails(window.location.origin.split("//")[1] + "/websocket");

var handleNew = function(response) {
	console.log(response);
};

dispatcher.bind('notify_user.new_notification', handleNew);
dispatcher.trigger("notify_user.connected", {foo: 1});

notifyUser.dispatcher = dispatcher;
notifyUser.dispatcher = dispatcher;
window.notifyUser = notifyUser;