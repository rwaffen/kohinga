require 'sinatra/activerecord/rake'
require 'rubocop/rake_task'
require './app'

RuboCop::RakeTask.new(:rubocop) do |t|
  t.options = ['--display-cop-names']
end
