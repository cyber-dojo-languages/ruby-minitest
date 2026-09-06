# Serves ruby's compiler from the cache of compiled instruction sequences that
# record_iseq_cache.rb wrote when this image was built, so a require reads
# bytecode instead of parsing source.
#
# Ruby provides the hook: whenever it is about to compile a file it calls
# RubyVM::InstructionSequence.load_iseq(path) and uses whatever instruction
# sequence comes back. Returning nil compiles the source as usual, which is
# what makes every failure below harmless.
#
# RUBYOPT names this file so the hook is installed before a kata's own requires
# run. Installing it any later would leave the framework already parsed.

module IseqCache
  # Set in the Dockerfile, and read there by the recorder too, so the two
  # halves cannot drift onto different directories.
  DIR = ENV.fetch('ISEQ_CACHE_DIR')

  # Mirrors the source tree under DIR, so /usr/local/lib/ruby/4.0.0/set.rb is
  # held at ${DIR}/usr/local/lib/ruby/4.0.0/set.rb.yarb. A mirrored path needs
  # no escaping, so no two sources can encode onto one entry.
  def self.entry_path(source_path)
    "#{DIR}#{source_path}.yarb"
  end
end

def (RubyVM::InstructionSequence).load_iseq(source_path)
  entry = IseqCache.entry_path(source_path)
  return nil unless File.exist?(entry)

  RubyVM::InstructionSequence.load_from_binary(File.binread(entry))
rescue StandardError
  # An entry that cannot be read, or that this ruby will not accept, costs
  # nothing: nil sends the file down the ordinary compile path. The cache can
  # therefore make a test run slower than it needs to be, never wrong.
  nil
end
