<!--
# @markup markdown
# @title Exports files
-->

# Description
Purpose configurations can have a file links section. This section can contain any number of file references. Each file has a name, which gets displayed on the download button in Limber that the user can click to get the file, an id (or key) which matches up to an entry in the `config/exports.yml`, and a file type.
e.g.
```yaml
:file_links:
    - name: 'Download My file'
      id: 'my_file_export_key'
      format: 'csv'
```

# Export file purpose config keys
The `config/exports.yml` file matches the id keys used in the file_links section in the purpose configurations to the code that builds the export file. Each key has a reference to an erb file located in the `views/exports` directory, e.g. in the example below to `app/views/exports/my_file_export_filename.csv.erb`.
You can also set other parameters here as needed. A common parameter is an `includes` line for fetching labware information needed for the export file.
e.g.
```yaml
my_file_export_key:
  csv: my_file_export_filename
  plate_includes: wells.aliquots.requests
  some_other_parameter: A value
```

See [`docs/exports_yaml_files.md`](./exports_yaml_files.md) for a more detailed description of this file.

# Export file formatting
See `app/views/exports/*.erb`
These erb files are what create the actual files for export. The start point is the file referenced in the `config/exports.yml` file, but then this file references other erb files in turn, many of which are common and re-used in multiple export files. Typically these first fetch information about the labware you clicked the export file button on, and then build up a series of rows for the file, usually sample by sample.
These export files can include anything that the lab staff may need for that specific pipeline step.
There are two common concentration file exports to download QC concentration data for a plate (one by mass in ng/ul and the other Molar) available for plate labwares.
The majority of the remaining pipeline-specific export files are either concentration files with additional sample metadata columns, or driver files for liquid handler robots that help with more complex transfers involving dilutions, re-distributions and pooling.
In some cases an export file including some empty columns is downloaded, filled in by the customer, and then re-uploaded in a downstream labware creator step to inform a transfer step.

Example liquid handler driver file:
```code
<%= CSV.generate_line [
                        'Workflow',
                        @workflow
                      ],
                      row_sep: ""
%>
<%= CSV.generate_line [
                        'Source Plate ID',
                        'Source Plate Well',
                        'Destination Plate ID',
                        'Destination Plate Well',
                        'Sample Vol'
                      ],
                      row_sep: ""
%>
<%
  rows_array = []
  @plate.wells_in_columns.each do |well|
    well.transfer_requests_as_target.each do |transfer_req|
      # NB. Making assumption here that name field on asset is for a plate well
      # and contains a plate barcode and well position e.g. DN12345678:A1
      name_array = transfer_req.source_asset.name.split(':')
      if name_array.length == 2
        rows_array << [
                        name_array[0],
                        name_array[1],
                        @plate.labware_barcode.human,
                        well.position['name'],
                        transfer_req.volume.round(2)
                      ]

      end
    end
  end
%>
<% rows_array.sort_by{ |a| WellHelpers.well_coordinate(a[1]) }.each do |row| %>
<%= CSV.generate_line row, row_sep: "" %>
<% end %>
```

Things to note about the above example and driver files in general:
- @plate is the current labware and coming from the Presenter, it will come from a lookup via the api and use the includes statement set in the `config/exports.yml` file.
- CSV.generate_line is what writes a row into the export file. It should be left justified in the erb.
- This erb loops through the wells in the plate in column order and then fetches information from the transfer requests for each well. The output CSV is a driver file, which has columns for the source (from) and destination (to) plate barcodes and the well coordinates, followed by the volume to be transferred.
- The format of this file is compatible with the specific liquid handler robot that will be using it. During development an example file from the specific liquid handler robot was provided by the Automation Team in R&D, and the output in the export file has been matched to that example. This includes the header rows, the order and spelling of the columns, the order of the rows, and the format of the plate barcodes, well coordinates and the volume. If something is not formatted correctly the liquid handler will not be able to understand how to transfer the samples.


Example concentration file:
This file is from the Duplex-Seq pipeline. It contains well concentrations, but also additional empty columns for the customers to fill in. The file is re-uploaded in a downstream labware creator step and used to make decisions about how the samples are transferred into the child plate there.
```code
<%= CSV.generate_line ['Plate Barcode', @plate.labware_barcode.human], row_sep: "" %>

<%= CSV.generate_line ['Well', 'Concentration (nM)', 'Sanger Sample Id', 'Supplier Sample Name', 'Input amount available (fmol)', 'Input amount desired', 'Sample volume', 'Diluent volume', 'PCR cycles', 'Submit for sequencing (Y/N)?', 'Sub-Pool', 'Coverage'], row_sep: "" %>
<% @plate.wells_in_columns.each do |well| %>
  <% unless well.empty? %>
<%= CSV.generate_line [well.location, well.latest_molarity&.value, well.sanger_sample_id, well.supplier_name, well.input_amount_available, nil, nil, nil, nil, nil, nil, nil], row_sep: "" %>
  <% end %>
<% end %>
```

Things to note about the above example:
- In addition to the concentration by well, extra sample metadata that the customer has requested is displayed.
- A number of columns are provided that are left blank for each row. These are for the customer to fill in. The file will be downloaded from Limber and sent by the SSRs to the customer via email. The customer knows their samples and decides what to next given their concentrations. The information informs dilution and pooling for the samples.
- The format of this file matches to that expected in the upload step in the downstream labware creator.
