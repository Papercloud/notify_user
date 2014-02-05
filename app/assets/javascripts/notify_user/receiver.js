var notifyUser = {};
window.notifyUser = notifyUser;
dispatcher = new WebSocketRails(window.location.origin.split("//")[1] + "/websocket");
notifyUser.dispatcher = dispatcher;

notifyUser.selectorToAppendNewMessagesTo = function() { return $('#notify-user-messages'); };


notifyUser.newMessageCb = function(response) {
  console.debug("Recieved Message" + response);
  notifyUser.selectorToAppendNewMessagesTo().append(response);
};

dispatcher.trigger("notify_user.connected", {}, function(id) {
    notifyUser.private_channel = dispatcher.subscribe_private(id);
    notifyUser.private_channel.on_success = function(id) {
			notifyUser.private_channel.bind('new_notification', notifyUser.newMessageCb);
			dispatcher.trigger('notify_user.test_new_notification');
    };

});

