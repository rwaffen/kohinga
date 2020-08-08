require 'action_view'
require 'config'
require 'digest'
require 'fileutils'
require 'mini_magick'
require 'octicons'
require 'sinatra'
require 'sinatra/activerecord'
require 'will_paginate'
require 'will_paginate/active_record'
require 'yaml'

require_relative 'lib/BootstrapLinkRenderer'
require_relative 'lib/Helpers'
require_relative 'lib/Models'

set :method_override, true

include ActionView::Helpers::TextHelper

Config.load_and_set_settings(
  "#{File.dirname(__FILE__)}/config/settings.yml"
)

get '/' do
  erb :index, :locals => {:message => nil }
end

get '/config' do
  erb :config
end

get '/folders' do
  @thumb_path   = Settings.thumb_path
  erb :folders, :locals => {:folder_root => "#{Settings.originals_path}/"}
end

post '/folder/create' do
  if params[:add_folder]
    folder_path   = "#{params['add_folder']}/"
    md5_path      = Digest::MD5.hexdigest(folder_path)

    parent_folder = "#{File.dirname(folder_path)}/"
    parent_md5    = Digest::MD5.hexdigest(parent_folder)

    FileUtils.mkdir_p folder_path

    Folder.find_or_create_by(md5_path: md5_path) do |folder|
      folder.folder_path   = folder_path
      folder.parent_folder = parent_folder
      folder.sub_folders   = Dir.glob("#{folder_path}*/")
      folder.md5_path      = md5_path
    end

    updates = Folder.find_by(md5_path: parent_md5)
    if updates.sub_folders != Dir.glob("#{parent_folder}*/")
      updates.sub_folders = Dir.glob("#{parent_folder}*/")
      updates.save
    end
  end

  redirect back
end

delete '/folder/delete/:md5' do
  folder        = Folder.find_by(md5_path: params[:md5])
  parent_folder = "#{folder.parent_folder}"

  FileUtils.rm_r folder.folder_path if File.directory?(folder.folder_path)

  updates = Folder.find_by(folder_path: parent_folder)
  if updates.sub_folders != Dir.glob("#{parent_folder}*/")
    updates.sub_folders = Dir.glob("#{parent_folder}*/")
    updates.save
  end

  folder.destroy
  redirect "/folders/#{parent_folder}"
end

get '/folders/*' do |path|
  @thumb_path   = Settings.thumb_path
  erb :folders, :locals => {:folder_root => path}
end

get '/image/:md5' do
  image = Image.find_by(md5_path: params[:md5])
  send_file("#{image.file_path}", :disposition => 'inline')
end

delete '/image/:md5' do
  image = Image.find_by(md5_path: params[:md5])
  File.delete(image.file_path) if File.exist?(image.file_path)
  image.destroy
  redirect back
end

post '/image/upload' do
  if params[:files]
    folder_path = params[:file_target].delete_suffix('/')

    params['files'].each do |file|
      target   = "#{folder_path}/#{file[:filename]}"
      md5_path = Digest::MD5.hexdigest(target)

      File.open(target, 'wb') { |f| f.write file[:tempfile].read }

      Image.find_or_create_by(md5_path: md5_path) do |image|
        image.file_path   = target
        image.folder_path = folder_path
        image.image_name  = File.basename(file[:filename], '.*')
        image.md5_path    = md5_path
      end

      create_thumb md5_path, Settings.thumb_target, Settings.thumb_res
    end
  end

  redirect back
end

get '/indexer' do
  build_index(
    Settings.originals_path,
    Settings.thumb_target,
    Settings.thumb_res,
    Settings.image_extentions
  )
  erb :index, :locals => {:message => 'Index ready'}
end
