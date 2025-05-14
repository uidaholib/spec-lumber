###############################################################################
# TASK: migrate_contentdm
#
# read csv, download using wget, generate derivatives, create new metadata fields
#
# expects a CSV that has required columns "objectid" and "cdmid" and "format", plus optional "collectionid"
#
###############################################################################

desc "migrate contentdm collection csv"
task :migrate_contentdm, [:csv_file,:cdm_collection_id,:output_dir] do |_t, args|
  # set default arguments
  args.with_defaults(
    csv_file: 'migrate.csv',
    cdm_collection_id: 'hwhi',
    output_dir: 'new'
  )
  # set some constants
  cdm_url = 'https://digital.lib.uidaho.edu'
  objects_url = 'https://objects.lib.uidaho.edu/' + args.output_dir
  # objects_url = 'https://ijc.uidaho.edu/objects/' + args.output_dir
  output_csv = args.output_dir + '_migrated.csv'
  output_csv_name = File.join(args.output_dir, output_csv)

  # check for csv file
  if !File.exist?(args.csv_file)
    puts "CSV file does not exist! No files downloaded and exiting."
  else
    # read csv file
    csv_text = File.read(args.csv_file, :encoding => 'utf-8')
    csv_contents = CSV.parse(csv_text, headers: true)

    # Ensure that the output directory exists.
    FileUtils.mkdir_p(args.output_dir) unless Dir.exist?(args.output_dir)
    
    # setup output data array
    output_array = []
    existing_fields = csv_contents.headers
    # add rows
    new_fields = 'display_template,filename,object_location,image_small,image_thumb,errors'.split(',')
    existing_fields.concat(new_fields)
    # add to output array
    output_array.push(existing_fields)
        
    # iterate on csv rows
    csv_contents.each_with_index do | item, index |
      # set item array for csv output
      item_array = item
      
      # check for required fields 
      if !item['objectid']

        puts "Skipping Row #{index} -- missing required objectid."
        # add to output array with error
        item_array.push(nil, nil, nil, nil, nil, 'missing objectid')
        # add to output array
        output_array.push(item_array)
        # skip, done
        next

      # youtube items
      elsif item['youtubeid']
        # create display_template, image_small, image_thumb
        item_display_template = "video"
        item_filename = nil
        item_object_location = "https://youtu.be/" + item['youtubeid']
        item_image_small = 'https://img.youtube.com/vi/' + item['youtubeid'] + '/hqdefault.jpg'
        item_image_thumb = 'https://img.youtube.com/vi/' + item['youtubeid'] + '/hqdefault.jpg'
        item_errors = nil
        # add fields
        item_array.push(item_display_template, item_filename, item_object_location, item_image_small, item_image_thumb, item_errors )
        # add to output array
        output_array.push(item_array)
        # done
        next

      # cdm items 
      elsif item['cdmid']
        # figure cdm collection 
        item_collection_id = item['collectionid'] ? item['collectionid'] : args.cdm_collection_id
        item_base_name = item['objectid']

        # figure out details based on format
        item_format = item['format']

        if item_format == "image/jpeg"
          item_display_template = "image"
          item_filename = item_base_name + ".jpg"
          item_object_location = objects_url + "/" + item_filename
          item_image_small = objects_url + "/small/" + item_base_name + "_sm.jpg"
          item_image_thumb = objects_url + "/thumbs/" + item_base_name + "_th.jpg"
          item_download = cdm_url + "/digital/iiif/" + item_collection_id + "/" + item['cdmid'] + "/full/max/0/default.jpg"

        elsif item_format == "application/pdf"
          item_display_template = "pdf"
          item_filename = item_base_name + ".pdf"
          item_object_location = objects_url + "/" + item_filename
          item_image_small = objects_url + "/small/" + item_base_name + "_sm.jpg"
          item_image_thumb = objects_url + "/thumbs/" + item_base_name + "_th.jpg"
          item_download = cdm_url + "/utils/getfile/collection/" + item_collection_id + "/id/" + item['cdmid'] + ".pdf"
          #item_download = "https://cdm17254.contentdm.oclc.org/digital/api/collection/" + item_collection_id + "/id/" + item['cdmid'] + "/download"
        
        elsif item_format == "html"
          item_display_template = "record"
          item_filename = item_base_name + ".html"
          item_object_location = objects_url + "/" + item_filename
          #item_image_small = objects_url + "/small/" + item_base_name + "_sm.jpg"
          #item_image_thumb = objects_url + "/thumbs/" + item_base_name + "_th.jpg"
          #item_download = cdm_url + "/utils/getfile/collection/" + item_collection_id + "/id/" + item['cdmid'] + ".pdf"
          item_download = "https://cdm17254.contentdm.oclc.org/digital/api/collection/" + item_collection_id + "/id/" + item['cdmid'] + "/download"

        elsif item_format == "audio/mp3"
          item_display_template = "audio"
          item_filename = item_base_name + ".mp3"
          item_object_location = objects_url + "/" + item_filename
          item_image_small = nil
          item_image_thumb = nil
          item_download = cdm_url + "/utils/getstream/collection/" + item_collection_id + "/id/" + item['cdmid'] 

        elsif item_format == "video/mp4"
          item_display_template = "video"
          item_filename = item_base_name + ".mp4"
          item_object_location = objects_url + "/" + item_filename
          item_image_small = nil
          item_image_thumb = nil
          item_download = cdm_url + "/utils/getstream/collection/" + item_collection_id + "/id/" + item['cdmid'] 

        else
          puts "Skipping Row #{index} -- unsupported format value."
          # add to output array with error
          item_array.push(nil, nil, nil, nil, nil, 'unsupport format value')
          # add to output array
          output_array.push(item_array)
          # skip, done
          next
        end

        # figure out download filename
        item_new_file = File.join(args.output_dir, item_filename)
        # check if file already exists
        if File.exist?(item_new_file)
            puts "Skipping Row #{index} -- new filename '#{item_new_file}' already exists."
            # add to output array with error
            item_array.push(item_display_template, item_filename, nil, nil, nil, 'conflicting filename')
            # add to output array
            output_array.push(item_array)
            # skip, done
            next
        end

        # download files
        # wget or https://github.com/janko/down
        puts "downloading"
        # call wget
        system('wget','-O', item_new_file, item_download)

        # add to output array with new fields
        item_array.push(item_display_template, item_filename, item_object_location, item_image_small, item_image_thumb, nil)
        # add to output array
        output_array.push(item_array)
        
      else 
        # doesn't have cdmid
        puts "Skipping Row #{index} -- missing required field cdmid."
        # add to output array with error
        item_array.push(nil, nil, nil, nil, nil, 'missing cdmid')
        # add to output array
        output_array.push(item_array)

      end
      # done with item

    end

    # write output csv
    CSV.open(output_csv_name, 'w') do |csv|
      output_array.each do |row|
        csv << row
      end
    end

    # run generate_derivatives on downloaded objects
    puts "Generating derivatives"
    Rake::Task['generate_derivatives'].invoke('450x','900x900','300',true,false,args.output_dir)

  end

end
