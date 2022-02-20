require_relative 'monocle'

def require_relative_dir(path)
  Dir.glob(File.join(File.dirname(__FILE__), path, '**/*.rb')).each do |rb|
    require rb
  end
end

# TODO move the rails monocles to the spec folder, they're not generic enough to be useful on their own, but good for beefing up test coverage
require_relative_dir('rails_monocles/snippets')
require_relative_dir('rails_monocles')