#This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
When /^I enter a valid user barcode$/ do
  fill_in("User Barcode", :with => "12343456454543")
end

When /^I enter a valid Source Plate barcode$/ do
  fill_in("Source Plate Barcode", :with => "22343456454543")
end

Then /^I am presented with a screen allowing me to create a destination plate$/ do
  pending # express the regexp above with the code you wish you had
end
