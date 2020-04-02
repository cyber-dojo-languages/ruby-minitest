export NO_COLOR=1 # turn off colour in report/coverage.txt
for test_file in *test*.rb
do
  ruby $test_file
done
