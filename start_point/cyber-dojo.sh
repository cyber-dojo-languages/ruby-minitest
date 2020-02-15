export NO_COLOR=1
for test_file in *test*.rb
do
  ruby $test_file
done
