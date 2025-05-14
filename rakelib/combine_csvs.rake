###############################################################################
# TASK: combine_csvs
#
# given a directory of csvs, read each, grab specific fields, output new combined csv
###############################################################################

desc "combine specific fields from a folder of csvs"
task :combine_csvs, [:input_dir,:field_list,:output_csv] do |_t, args|
    # set default arguments
    args.with_defaults(
        input_dir: 'csvs',
        field_list: 'objectid;title;cdmid',
        output_csv: 'combined.csv'
    )

    # check for existing csv file
    if File.exist?(args.output_csv)
        puts "Output CSV already exists! Please change output name. No CSVs combined, exiting."
        next
    end

    # set up output data array
    output_array = []
    output_fields = args.field_list.split(';')
    output_header = args.field_list.split(';')
    output_header.push("source_csv")
    output_array.push(output_header)

    # Iterate over all csv files in input directory
    Dir.glob(File.join(args.input_dir, '*.csv')).each do |filename|
        # read the csv
        csv_file = File.read(filename, :encoding => 'utf-8')
        csv_contents = CSV.parse(csv_file, headers: true)
        csv_filename = File.basename(filename)
        # iterate on csv rows to extract fields
        csv_contents.each do |item|
            new_row = []
            output_fields.each do |field|
                if item[field]
                    new_row.push(item[field])
                else
                    new_row.push(nil)
                end
            end
            # add source file
            new_row.push(csv_filename)
            # add to output
            output_array.push(new_row)
        end
    end

    # write output csv
    CSV.open(args.output_csv, 'w') do |csv|
        output_array.each do |row|
            csv << row
        end
    end

end