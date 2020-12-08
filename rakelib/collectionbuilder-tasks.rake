# Enclose CollectionBuilder-related tasks in a namespaced called "cb", to be
# executed using the convention: `rake cb:{task_name}`
namespace :cb do

  ###############################################################################
  # helpers
  ###############################################################################
  
  # If a specified directory doesn't exist, create it.
  $ensure_dir_exists = ->(dir) { if !Dir.exists?(dir) then Dir.mkdir(dir) end }
  
  # Abort if the env value specified to a rake task is invalid.
  def assert_env_arg_is_valid env, valid_envs=["DEVELOPMENT", "PRODUCTION_PREVIEW", "PRODUCTION"]
    if !valid_envs.include? env
      abort "Invalid environment value: \"#{env}\". Please specify one of: #{valid_envs}"
    end
  end

  # Abort if the env value specified to a rake task is invalid.
  def assert_required_args args, req_args
    # Assert that the task args object includes a non-nil value for each arg in req_args.
    missing_args = req_args.filter { |x| !args.has_key?(x) or args.fetch(x) == nil }
    if missing_args.length > 0
      abort "The following required task arguments must be specified: #{missing_args}"
    end
  end

  # Prompt the user to confirm that they want to do what the message says
  # and return a bool indicating their response.
  def prompt_user_for_confirmation message
    response = nil
    while true do
      # Use print instead of puts to avoid trailing \n.
      print "#{message} (Y/n): "
      $stdout.flush
      response =
        case STDIN.gets.chomp.downcase
        when "", "y"
          true
        when "n"
          false
        else
          nil
        end
      if response != nil
        return response
      end
      puts "Please enter \"y\" or \"n\""
    end
  end


  ###############################################################################
  # deploy
  ###############################################################################

  desc "Build site with production env"
  task :deploy do
    ENV['JEKYLL_ENV'] = "production"
    sh "jekyll build --config _config.yml,_config.production.yml"
  end


  ###############################################################################
  # serve
  ###############################################################################

  desc "Run the local web server"
  task :serve, [:env] do |t, args|
    args.with_defaults(
      :env => "DEVELOPMENT"
    )
    assert_env_arg_is_valid args.env, [ 'DEVELOPMENT', 'PRODUCTION_PREVIEW' ]
    env = args.env.to_sym
    config_filenames = $ENV_CONFIG_FILENAMES_MAP[env]
    sh "jekyll s --config #{config_filenames.join(',')} -H 0.0.0.0"
  end


  ###############################################################################
  # generate_derivatives
  ###############################################################################

  desc "Generate derivative image files from collection objects"
  task :generate_derivatives, [:thumbs_size, :small_size, :density, :missing, :im_executable] do |t, args|
    args.with_defaults(
      :thumbs_size => "300x300",
      :small_size => "800x800",
      :density => "90",
      :missing => "true",
      :im_executable => "magick",
    )

    config = load_config :DEVELOPMENT
    objects_dir = config[:objects_dir]
    thumb_images_dir = config[:thumb_images_dir]
    small_images_dir = config[:small_images_dir]

    # Ensure that the output directories exist.
    [thumb_images_dir, small_images_dir].each &$ensure_dir_exists

    EXTNAME_TYPE_MAP = {
      '.jpg' => :image,
      '.pdf' => :pdf
    }

    # Generate derivatives.
    Dir.glob(File.join([objects_dir, '*'])).each do |filename|
      # Ignore subdirectories.
      if File.directory? filename
        next
      end

      # Determine the file type and skip if unsupported.
      extname = File.extname(filename).downcase
      file_type = EXTNAME_TYPE_MAP[extname]
      if !file_type
        puts "Skipping file with unsupported extension: #{extname}"
        next
      end

      # Define the file-type-specific ImageMagick command prefix.
      cmd_prefix =
        case file_type
        when :image then "#{args.im_executable} #{filename}"
        when :pdf then "#{args.im_executable} -density #{args.density} #{filename}[0]"
        end

      # Get the lowercase filename without any leading path and extension.
      base_filename = File.basename(filename, extname).downcase

      # Generate the thumb image.
      thumb_filename=File.join([thumb_images_dir, "#{base_filename}_th.jpg"])
      if args.missing == 'false' or !File.exists?(thumb_filename)
        puts "Creating: #{thumb_filename}";
        system("#{cmd_prefix} -resize #{args.thumbs_size} -flatten #{thumb_filename}")
      end

      # Generate the small image.
      small_filename = File.join([small_images_dir, "#{base_filename}_sm.jpg"])
      if args.missing == 'false' or !File.exists?(small_filename)
        puts "Creating: #{small_filename}";
        system("#{cmd_prefix} -resize #{args.small_size} -flatten #{small_filename}")
      end
    end
  end


  ###############################################################################
  # normalize_object_filenames
  ###############################################################################

  desc "Rename the object files to match their corresponding objectid metadata value"
  task :normalize_object_filenames, [:force] do |t, args|
    args.with_defaults(
      :force => "false"
    )
    force = args.force == "true"

    config = load_config :DEVELOPMENT
    objects_dir = config[:objects_dir]
    objects_backup_dir = File.join([objects_dir, '_prenorm_backup'])

    FORMAT_EXTENSION_MAP = {
      'image/jpg' => '.jpg',
      'application/pdf' => '.pdf'
    }

    VALID_FORMATS = Set[*FORMAT_EXTENSION_MAP.keys]

    def get_normalized_filename(objectid, format)
      return "#{objectid}#{FORMAT_EXTENSION_MAP[format]}"
    end

    # Prompt whether user wants to continue if a non-empty backup
    # directory already exists.
    if Dir.exists?(objects_backup_dir) and !Dir.empty?(objects_backup_dir)
      res = prompt_user_for_confirmation "It looks like your object filenames " \
                                         "have already been normalized. Skip this step?"
      if res == true
        next
      end
    end

    # Do a dry run to check that:
    #  - there are no objectid collisions
    #  - there are no filename collisions
    #  - all format values are valid
    #  - all referenced filenames are present
    #  - the existing filename extension matches the format
    #  - no renamed filename will overwrite an existing
    seen_objectids = Set[]
    duplicate_objectids = Set[]
    seen_filenames = Set[]
    duplicate_filenames = Set[]
    invalid_formats = Set[]
    missing_files = Set[]
    invalid_extensions = Set[]
    existing_filename_collisions = Set[]
    num_items = 0
    config[:metadata].each do |item|
      # Check for objectids collisions.
      objectid = item['objectid']
      if seen_objectids.include? objectid
        duplicate_objectids.add objectid
      else
        seen_objectids.add objectid
      end

      # Check that the format is valid.
      format = item['format']
      if !VALID_FORMATS.include? format
        invalid_formats.add format
      end

      filename = item['filename']
      # Check for metadata filename collisions.
      if seen_filenames.include? filename
        duplicate_filenames.add filename
      else
        seen_filenames.add filename
      end
      # Check whether the file exists.
      if !File.exist? File.join([objects_dir, filename])
        missing_files.add filename
      end

      # Check that the existing filename extension matches the format.
      extension = File.extname(filename)
      if extension != FORMAT_EXTENSION_MAP[format]
        invalid_extensions.add extension
      end

      # If the new filename is different than the one specified in the metadata,
      # Check that the new filename will not overwrite an existing file.
      normalized_filename = get_normalized_filename(objectid, format)
      if normalized_filename != filename and File.exist? File.join([objects_dir, normalized_filename])
        existing_filename_collisions.add normalized_filename
      end

      num_items += 1
    end

    if (duplicate_objectids.size +
        duplicate_filenames.size +
        invalid_formats.size +
        missing_files.size +
        invalid_extensions.size +
        existing_filename_collisions.size
       ) > 0
      print "The following errors were detected:\n"
      if duplicate_objectids.size > 0
        print " - metadata contains duplicate 'objectid' value(s): #{duplicate_objectids.to_a}\n"
      end
      if duplicate_filenames.size > 0
        print " - metadata contains duplicate 'filename' value(s): #{duplicate_filenames.to_a}\n"
      end
      if invalid_formats.size > 0
        print " - metadata specifies unsupported 'format' value(s): #{invalid_formats.to_a}\n"
      end
      if missing_files.size > 0
        print " - metadata specifies 'filename' value(s) for which a file does not exist: #{missing_files.to_a}\n"
      end
      if invalid_extensions.size > 0
        print " - existing filename extensions do not match their format: #{invalid_extensions.to_a}\n"
      end
      if existing_filename_collisions.size > 0
        print " - renamed files would have overwritten existing files: #{existing_filename_collisions.to_a}\n"
      end
      if !force
        # Abort the task
        abort
      else
        print "The 'force' argument was specified, continuing...\n"
      end
    end

    # Everything looks good - do the renaming.
    res = prompt_user_for_confirmation "Rename #{num_items} files to match their objectid?"
    if res == false
      abort
    end

    # Optionally backup the original files.
    res = prompt_user_for_confirmation "Create backups of the original files in #{objects_backup_dir} ?"
    if res == true
      $ensure_dir_exists.call objects_backup_dir
      Dir.glob(File.join([objects_dir, '*'])).each do |filename|
        if !File.directory? filename
          FileUtils.cp(
            filename,
            File.join([objects_backup_dir, File.basename(filename)])
          )
        end
      end
    end

    config[:metadata].each do |item|
      objectid = item['objectid']
      filename = item['filename']
      format = item['format']

      normalized_filename = get_normalized_filename(objectid, format)

      # Leave the file alone if its filename is already normalized.
      if normalized_filename == filename
        next
      end

      existing_path = File.join([objects_dir, filename])
      new_path = File.join([objects_dir, normalized_filename])
      File.rename(existing_path, new_path)

      print "Renamed \"#{existing_path}\" to \"#{new_path}\"\n"
    end

    # Check whether any files with a filename derived from the old filenames exist.
    extracted_text_files = Dir.glob("#{config[:extracted_pdf_text_dir]}/*")
    derivative_files = (Dir.glob("#{config[:thumb_images_dir]}/*") +
                        Dir.glob("#{config[:small_images_dir]}/*"))

    if extracted_text_files.size > 0
      print "\nIt looks like you ran the extract_pdf_text task before normalizing the filenames. Since the extracted text files are given names that are based on that of the original file, you need to delete the existing files and run the extract_pdf_text task again.\n"
      res = prompt_user_for_confirmation "Delete the existing extracted PDF text files now?"
      if res == true
        FileUtils.rm extracted_text_files
      end
      print "Deleted #{extracted_text_files.size} extracted text files from \"#{config[:extracted_pdf_text_dir]}\". Remember to rerun the extract_pdf_text rake task.\n"
    end

    if derivative_files.size > 0
      print "\nIt looks like you ran the generate_derivatives task before normalizing the filenames. Since the direvative files are given names that are based on that of the original file, you need to delete the existing files and run the generate_derivatives task again.\n"
      res = prompt_user_for_confirmation "Delete the existing derivative files now?"
      if res == true
        FileUtils.rm derivative_files
        print "Deleted #{derivative_files.size} derivative files from \"#{config[:thumb_images_dir]}\" and/or \"#{config[:small_images_dir]}\". Remember to rerun the generate_derivatives rake task.\n"
      end
    end

  end

# Close the namespace.
end
