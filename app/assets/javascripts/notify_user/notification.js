$( document ).ready(function() {
	$('.message').click(function(){
		item = $(this).parent().parent();
		item.addClass('read');
			
	});
});
