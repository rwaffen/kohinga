require 'digest'
require 'fileutils'
require 'mini_magick'
require 'pp'
require 'sinatra/activerecord'

require_relative 'lib/Models'
require_relative 'lib/Helpers'

thumbs_path = 'public/images/thumbs'
thumb_size  = '200x300^' # the ^ is intentional, it is to crop the thumbs
image_root  = 'data/images'
extensions  = ['jpg', 'jpeg', 'png']
