# Records the cache of compiled instruction sequences that serve_iseq_cache.rb
# replays, and which every kata's test run then reads instead of parsing the
# test framework's source again.
#
# A kata runs in a container thrown away afterwards, so each test run parses
# and compiles minitest, mocha, simplecov and the part of the standard library
# they pull in, all of it identical on every run of every kata in this image.
# Measured on this image that is most of a test run rather than a part of it:
# the tests themselves finish in under a millisecond.
#
# A learner's own files are never cached, which is what keeps their edits
# taking effect. The hook keys purely on path, so a cached kata file would go
# on running its build-time bytecode however the learner changed it, which is
# a wrong traffic-light rather than a slow one. Two things prevent it: nothing
# under CYBER_DOJO_SANDBOX exists yet when this runs, and ROOTS below refuses
# any directory outside /usr/local even so.
#
# Instruction sequences are specific to the ruby that wrote them. Here the
# writer and the reader are the same ruby in the same image, so that holds by
# construction; it does mean this has to run again in the same build step as
# any ruby upgrade rather than being carried forward.

require 'fileutils'

CACHE_DIR = ENV.fetch('ISEQ_CACHE_DIR')

# The only directories a kata loads library code from. Confining the walk to
# them is what stops the cache ever holding a file a learner can edit.
PERMITTED_ROOT = '/usr/local'

def source_dirs
  dirs = Gem::Specification.map(&:full_require_paths).flatten + $LOAD_PATH
  dirs.map { |dir| File.expand_path(dir) }
      .select { |dir| dir.start_with?("#{PERMITTED_ROOT}/") }
      .select { |dir| File.directory?(dir) }
      .uniq
end

def record(source_path)
  binary = RubyVM::InstructionSequence.compile_file(source_path).to_binary
  entry = "#{CACHE_DIR}#{source_path}.yarb"
  FileUtils.mkdir_p(File.dirname(entry))
  File.binwrite(entry, binary)
  # The sandbox user reads every entry at run time and owns none of them.
  File.chmod(0o644, entry)
  binary.bytesize
rescue StandardError, SyntaxError
  # Gems ship ruby files that are not meant to be loaded by this ruby at all:
  # fixtures that deliberately will not parse, and sources for other versions.
  # Skipping one costs a parse on the run that requires it, if anything ever
  # does, so there is nothing here worth failing the build over.
  nil
end

recorded = 0
skipped = 0
bytes = 0

source_dirs.each do |dir|
  Dir.glob("#{dir}/**/*.rb").sort.each do |source_path|
    next unless File.file?(source_path)

    size = record(source_path)
    if size
      recorded += 1
      bytes += size
    else
      skipped += 1
    end
  end
end

FileUtils.chmod_R('a+rX', CACHE_DIR)

puts "iseq cache: #{recorded} files, #{bytes / 1024}KB, in #{CACHE_DIR}"
puts "iseq cache: #{skipped} files skipped, which will be parsed if required"
