#!/bin/bash

balls::define_route() {
  local verb=$1; shift
  local path=$1; shift
  local action=$1; shift

  local route_line="$(echo -e "$verb\t$path\t$action")"
  if [ -z "$ROUTES" ]; then
    ROUTES="$route_line"
  else
    ROUTES="$ROUTES
$route_line"
  fi
}

b:GET() { balls::define_route GET "$@" ;}
b:POST() { balls::define_route POST "$@" ;}
b:PUT() { balls::define_route PUT "$@" ;}
b:DELETE() { balls::define_route DELETE "$@" ;}

balls::route() {
  [[ "$BALLS_RELOAD" = 1 ]] && balls::load_app
  [[ "$REQUEST_METHOD" = "HEAD" ]] && body_sock=/dev/null

  local action=$(
    echo "$ROUTES" | grep "^$REQUEST_METHOD" | {
      while read line; do
        arr=($line)
        path=${arr[1]}
        act=${arr[2]}
        if [[ "$REQUEST_PATH" == "$path"* ]]; then
          echo $act
          break
        fi
      done
    }
  )
	
  if [ -n "$action" ] && exists "$action"; then
    balls::execute_action $action
  else
    if [[ "$REQUEST_METHOD" = "HEAD" ]]; then
      REQUEST_METHOD=GET
      balls::route
    else
      balls::execute_action filenotfound
    fi

  fi
}
balls::execute_action() {
    local action=$1
    headers_sock=$BALLS_TMP/balls.headers.$(_hash).sock
    [ -p $headers_sock ] || mkfifo $headers_sock

    ( $action 3>$headers_sock ) | {
      headers=$(cat <$headers_sock)
      stderr "$headers"
      body=$(cat -)
      response=$(
        echo "$headers"
        echo "Content-Length: ${#body}"
        echo
        echo "$body"
      )

      echo "$response"
    }
    rm -f "$headers_sock"
}
