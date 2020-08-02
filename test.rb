require 'config'
require 'digest'
require 'fileutils'
require 'mini_magick'
require 'pp'
require 'sinatra/activerecord'

require_relative 'lib/Helpers'
require_relative 'lib/Models'

thumbs_path = 'public/images/thumbs'
thumb_size  = '200x300^' # the ^ is intentional, it is to crop the thumbs
image_root  = 'data/images'
extensions  = ['jpg', 'jpeg', 'png']

Config.load_and_set_settings("#{File.dirname(__FILE__)}/config/settings.yml")

settings_yaml = YAML.load_file('config/settings.yml')

settings_yaml.each do |key, value|
  pp key, value
end
