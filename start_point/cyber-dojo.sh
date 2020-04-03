set -e

# remove existing coverage report
[ -e report/coverage.txt ] && rm report/coverage.txt
# turn off colour for new coverge report
export NO_COLOR=1

for test_file in *test*.rb
do
  ruby $test_file
done
