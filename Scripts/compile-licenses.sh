#!/bin/bash

cd "$(dirname "$0")/.."

cat <<HTML > Credits.html
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
  </head>
	<body>
		<pre>
$(/usr/local/bin/licenses)
		</pre>
	</body>
</html>
HTML