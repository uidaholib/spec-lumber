###############################################################################
# TASK: move_by_csv
#
# read csv, move files
###############################################################################

desc "move objects from csv list"
task :move_by_csv, [:csv_file,:filename_current,:input_dir,:output_dir] do |_t, args|
  # set default arguments
  args.with_defaults(
    csv_file: 'move.csv',
    filename_current: 'filename',
    input_dir: 'objects/',
    output_dir: 'moved/'
  )

  # check for csv file
  if !File.exist?(args.csv_file)
    puts "CSV file does not exist! No files renamed and exiting."
  else
    # read csv file
    csv_text = File.read(args.csv_file, :encoding => 'utf-8')
    csv_contents = CSV.parse(csv_text, headers: true)

    # Ensure that the output directory exists.
    FileUtils.mkdir_p(args.output_dir) unless Dir.exist?(args.output_dir)

    # iterate on csv rows
    csv_contents.each do |item|
      # check for filename
      if item[args.filename_current]
        name_old = File.join(args.input_dir, item[args.filename_current])
      else
        puts "no current filename given, skipping!"
        next
      end
      # set new file name
      name_new = File.join(args.output_dir, item[args.filename_current])
      # check if old and new file exist
      if !File.exist?(name_old)
        puts "old file '#{name_old}' does not exist, skipping!"
        next
      end
      if File.exist?(name_new)
        puts "new filename '#{name_new}' already exists, skipping!"
        next
      end
      # move the file by copying
      puts "copying: '#{name_old}' to '#{name_new}'"
      system('cp', name_old, name_new)
    end
    
    puts "done moving."

  end

end
