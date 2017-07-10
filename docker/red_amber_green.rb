
lambda { |stdout,stderr,status|
  output = stdout + stderr
  ruby_pattern = Regexp.new('^(\d+) runs, (\d+) assertions, (\d+) failures, (\d+) errors')
  if match = ruby_pattern.match(output)
    return :amber if match[4] != '0'
    return :red   if match[3] != '0'
    return :green
  else
    return :amber
  end
}
