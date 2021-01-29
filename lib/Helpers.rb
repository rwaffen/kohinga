def index_files(path, extensions)
  files_list = []
  files = []

  extensions.each do |extension|
    # FNM_CASEFOLD is for case insensivity
    files << Dir.glob("#{path}/**/*.#{extension}", File::FNM_CASEFOLD)
  end

  files.flatten.each do |file|
    if Settings.movie_extentions.include? File.extname(file).delete('.')
      files_list << {
        file_path: file,
        folder_path: File.dirname(file),
        image_name: File.basename(file, '.*'),
        md5_path: Digest::MD5.hexdigest(file),
        is_video: true,
        is_image: false
      }
    end

    next unless Settings.image_extentions.include? File.extname(file).delete('.')

    files_list << {
      file_path: file,
      folder_path: File.dirname(file),
      image_name: File.basename(file, '.*'),
      md5_path: Digest::MD5.hexdigest(file),
      fingerprint: Phashion::Image.new(file).fingerprint,
      is_image: true,
      is_video: false
    }
  end

  files_list
end

def index_folders(path)
  folder_list = []

  Dir.glob("#{path}/**/").each do |folder|
    folder_list << {
      md5_path: Digest::MD5.hexdigest(folder),
      folder_path: folder,
      parent_folder: "#{File.dirname(folder)}/",
      sub_folders: Dir.glob("#{folder}*/")
    }
  end

  folder_list
end

def write_files_to_db(file_hash)
  logger.info 'writing new files to db ...'

  file_hash.each do |file|
    logger.debug "processing: #{file[:file_path]}"
    Image.find_or_create_by(md5_path: file[:md5_path]) do |image|
      if Settings.image_extentions.include? File.extname(file[:file_path]).delete('.')
        duplicates = Image.where(fingerprint: file[:fingerprint])

        if duplicates.size > 1
          image.duplicate = true
          duplicates.each { |dupe| image.duplicate_of = dupe.file_path }
        else
          image.duplicate = false
        end
      end

      image.file_path    = file[:file_path]
      image.fingerprint  = file[:fingerprint]
      image.folder_path  = file[:folder_path]
      image.image_name   = file[:image_name]
      image.is_image     = file[:is_image]
      image.is_video     = file[:is_video]
      image.md5_path     = file[:md5_path]
      image.save
    end
  end
end

def write_folders_to_db(folder_hash)
  logger.info 'writing new folders to db ...'

  folder_hash.each do |folder_path|
    logger.debug "processing: #{folder_path[:folder_path]}"

    Folder.find_or_create_by(md5_path: folder_path[:md5_path]) do |folder|
      folder.folder_path   = folder_path[:folder_path]
      folder.parent_folder = folder_path[:parent_folder]
      folder.sub_folders   = folder_path[:sub_folders]
      folder.md5_path      = folder_path[:md5_path]
    end

    updates = Folder.find_by(md5_path: folder_path[:md5_path])
    if updates.sub_folders != folder_path[:sub_folders]
      updates.sub_folders = folder_path[:sub_folders]
      updates.save
    end
  end
end

def create_thumbs(thumb_target, size)
  logger.info 'creating new thumbs ...'

  FileUtils.mkdir_p thumb_target
  Image.all.each do |image|
    image_path = "#{thumb_target}/#{image.md5_path}.png"

    # only create thumbs if we do not have them already
    next if File.file?(image_path)

    # handle movie files
    if Settings.movie_extentions.include? File.extname(image.file_path).delete('.')
      # "try" block
      begin
        movie = FFMPEG::Movie.new(image.file_path)
        movie.screenshot(
          image_path,
          { seek_time: 1, resolution: size[0...-1], quality: 3 },
          preserve_aspect_ratio: :hight
        )
        logger.info "generated: #{image_path}"
      rescue Exception => e
        logger.info "Error: #{e.message}"
      end
    end

    # handle image files
    next unless Settings.image_extentions.include? File.extname(image.file_path).delete('.')

    # "try" block
    begin
      convert = MiniMagick::Tool::Convert.new
      convert << image.file_path # input file
      convert.resize(size)
      convert.gravity('north')
      convert.extent(size)
      convert << image_path # output file
      convert.call
      logger.info "generated: #{image_path}"
    rescue Exception => e
      logger.info "Error: #{e.message}"
    end
  end
end

def create_thumb(md5, thumb_target, size)
  image      = Image.find_or_create_by(md5_path: md5)
  image_path = "#{thumb_target}/#{md5}.png"

  if Settings.movie_extentions.include? File.extname(image.file_path).delete('.')
    movie = FFMPEG::Movie.new(image.file_path)
    movie.screenshot(
      image_path,
      { seek_time: 1, resolution: size[0...-1], quality: 3 },
      preserve_aspect_ratio: :hight
    )
  end

  if Settings.image_extentions.include? File.extname(image.file_path).delete('.')
    convert = MiniMagick::Tool::Convert.new
    convert << image.file_path # input file
    convert.resize(size)
    convert.gravity('north')
    convert.extent(size)
    convert << image_path # output file
    convert.call
  end

  logger.info "generated: #{image_path}"
end

def remove_file(thumb_target)
  logger.info 'removing obsolete files ...'

  Image.all.each do |image|
    image_path = image.file_path
    thumb_path = "#{thumb_target}/#{image.md5_path}.png"

    next if File.file?(image_path)

    logger.info "removing image from db: #{image.file_path}"
    image.destroy

    if File.file?(thumb_path)
      logger.info "removing thumbnail from fs: #{thumb_path}"
      File.delete(thumb_path)
    end
  end
end

def remove_folder
  logger.info 'removing obsolete folders ...'

  Folder.all.each do |folder|
    folder_path = folder.folder_path

    unless File.directory?(folder_path)
      logger.info "removing folder from db: #{folder.folder_path}"
      folder.destroy
    end
  end
end

def build_index(image_root, thumb_target, thumb_size, extensions)
  remove_file(thumb_target)
  remove_folder
  write_folders_to_db(index_folders(image_root))
  write_files_to_db(index_files(image_root, extensions))
  create_thumbs(thumb_target, thumb_size)
  find_duplicates
end

def find_duplicates
  logger.info 'finding duplicates ...'

  Image.find_each do |image|
    if image.is_image
      if image.fingerprint.nil?
        logger.info "genrating image fingerprint for #{image.file_path}"
        fingerprint       = Phashion::Image.new(image.file_path).fingerprint
        image.fingerprint = fingerprint
      end

      duplicates = Image.where(fingerprint: image.fingerprint)

      if duplicates.size > 1
        image.duplicate = true
        duplicates.each { |dupe| image.duplicate_of = dupe.file_path }
        image.save
      else
        image.duplicate = false
        image.save
      end
    end
  end
end
