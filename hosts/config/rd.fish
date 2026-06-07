function __rd_complete
  set -l tok (commandline -ct)
  set -l host dev
  set -l partial "$tok"
  set -l has_host 0

  if string match -q "*:*" -- $tok
    set host (string replace -r ":.*" "" -- $tok)
    set partial (string replace -r ".*:" "" -- $tok)
    set has_host 1
  end

  if test -z "$partial"
    set partial "~/"
  end

  # Expand ~ to absolute path on the remote and return absolute paths
  # Fish internally expands ~ and matches against absolute paths
  set -l results (ssh -o ConnectTimeout=2 $host "ls -1dp $partial* 2>/dev/null | head -50" 2>/dev/null)

  for r in $results
    if test $has_host -eq 1
      echo "$host:$r"
    else
      echo "$r"
    end
  end
end

complete -c rd -f -a '(__rd_complete)'
