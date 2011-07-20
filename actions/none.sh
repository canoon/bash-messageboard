b:GET '/thread/' thread
#b:POST '/thread/' update
b:GET '/test' asdf


filenotfound() {
	http::status 404
	echo $REQUEST_PATH could not be found...
}

thread() {
	local thread=`basename "$REQUEST_PATH"`
	local thread_file="db/$thread"
	touch $thread_file
	if [[ ! "$QUERY_STRING" == "" ]]; then
		echo "$QUERY_STRING" | sed 's/name=//' | sed 's/comment=//' | sed 's/&/:/' >> $thread_file
		http::status '302' 'Found'
		http::header 'Location' "/thread/$thread"
		echo "Moved"
	else
        	if [ -f $thread_file ]; then
			http::status '200'
			http::content_type "text/html"
			cat db/$thread | sed 's/\([^:]*\):\(.*\)/name: \1<br>\2<br><br>/'
			echo "<form action='' method='get'>Name: <input type='text' name='name'><br>Message: <input type='text' name='comment'><input type='submit'></form>"
		else
			http::status '404'
			echo "Thread not found"
		fi
	fi

	
}



asdf() {
	http::status '200'
	ls	
}
