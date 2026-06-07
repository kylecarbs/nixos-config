complete -c rd -f -a '(
  set -l tok (commandline -ct)

  if string match -q "*:*" -- $tok
    set -l host (string replace -r ":.*" "" -- $tok)
    set -l partial (string replace -r ".*:" "" -- $tok)
  else
    set -l host dev
    set -l partial $tok
  end

  # Default to home dir if nothing typed yet
  if test -z "$partial"
    set partial "~/"
  end

  set -l results (ssh -o ConnectTimeout=2 $host "ls -1dp $partial* 2>/dev/null | head -50" 2>/dev/null)
  for r in $results
    if string match -q "*:*" -- $tok
      echo "$host:$r"
    else
      echo "$r"
    end
  end
)'
