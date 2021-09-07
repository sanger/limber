# frozen_string_literal
require 'csv'
cardinal_pooling_csv = CSV.read('config/cardinal_pooling.csv', { encoding: "UTF-8", headers: true, header_converters: :symbol, converters: :all})

# hashed_data = data.map { |d| d.to_hash }
# => [
# {:name=>"Alberto", :lastname=>"Grespan", :email=>"ag@gmail.com", :birth_date=>"30/11/1986", :hometown=>"Mérida"},
# {:name=>"Pedro", :lastname=>"Perez", :email=>"pp@gmail.com", :birth_date=>"4/4/1984", :hometown=>"Caracas"},
# {:name=>"John", :lastname=>"Doe", :email=>"jd@gmail.com", :birth_date=>nil, :hometown=>"Kansas"},
# {:name=>"José", :lastname=>"González", :email=>"jg@gmail.com", :birth_date=>"16/10/1984", :hometown=>"Madrid"},
# {:name=>"Andrés", :lastname=>"Márquez", :email=>nil, :birth_date=>"18/3/1987", :hometown=>"Caracas"}
# ]
LabwareCreators::CardinalPoolsPlate.pooling_config = {}

cardinal_pooling_csv.each do |data|
    contents = data.to_hash
    LabwareCreators::CardinalPoolsPlate.pooling_config[contents[:number]] = data.to_hash
end
