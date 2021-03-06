require 'config'
require 'digest'
require 'fileutils'
require 'mini_magick'
require 'sinatra/activerecord'
require 'streamio-ffmpeg'
require 'yaml'

require_relative 'lib/Helpers'
require_relative 'lib/Models'

Config.load_and_set_settings("#{File.dirname(__FILE__)}/config/settings.yml")

build_index(
  Settings.originals_path,
  Settings.thumb_target,
  Settings.thumb_res,
  Settings.image_extentions + Settings.movie_extentions
)
