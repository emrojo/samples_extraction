require 'rails_helper'

RSpec.describe Asset, type: :model do
  describe 'Export' do
    context '#racking_info' do
      it 'generates an attribute object for a well' do
        facts = %Q{
          :s1 :a :SampleTube .
          :s2 :a :SampleTube .
          :s3 :a :SampleTube .
          :s4 :a :SampleTube .
          :tube1   :a                 :Tube ;
                   :location          "A1" ;
                   :sample_tube       :s1 .
          :tube2   :a                 :Tube ;
                   :location          "B1" ;
                   :sample_tube       :s2 .
          :tube3   :a                 :Tube ;
                   :location          "C1" ;
                   :sample_tube       :s3 .
          :tube4   :a                 :Tube ;
                   :location          "D1" ;
                   :sample_tube       :s4 .

          :rack1   :a                 :TubeRack ;
                   :contains          :tube1, :tube2, :tube3, :tube4 .
        }
        @assets = SupportN3::parse_facts(facts)
        
        @rack1 = Asset.find_by(uuid: 'rack1')
        expect(@rack1.attributes_to_update).to eq([
          {sample_tube_uuid: "s1", location: "A1"},
          {sample_tube_uuid: "s2", location: "B1"},
          {sample_tube_uuid: "s3", location: "C1"},
          {sample_tube_uuid: "s4", location: "D1"}])
      end

    end
    context '#attributes_to_update' do
      it 'generates the attributes when the locations are not duplicated' do
        facts = %Q{
          :s1 :a :SampleTube .
          :s2 :a :SampleTube .
          :s3 :a :SampleTube .
          :s4 :a :SampleTube .
          :rack2   :a                 :TubeRack ;
                   :contains          :tube1, :tube2, :tube3, :tube4 .

          :tube1   :a                 :Tube ;
                   :location          "A1" ;
                   :sample_tube       :s1 .
          :tube2   :a                 :Tube ;
                   :location          "B1" ;
                   :sample_tube       :s2 .
          :tube3   :a                 :Tube ;
                   :location          "C1" ;
                   :sample_tube       :s3 .
          :tube4   :a                 :Tube ;
                   :location          "D1" ;
                   :sample_tube       :s4 .
        }
        @assets = SupportN3::parse_facts(facts)
        @rack2 = Asset.find_by(uuid: 'rack2')
        expect(@rack2.attributes_to_update).to eq([
          {sample_tube_uuid: "s1", location: "A1"},
          {sample_tube_uuid: "s2", location: "B1"},
          {sample_tube_uuid: "s3", location: "C1"},
          {sample_tube_uuid: "s4", location: "D1"}])
      end

      it 'fails when trying to generate attributes when the locations are duplicated' do
        facts = %Q{
          :s1 :a :SampleTube .
          :s2 :a :SampleTube .
          :s3 :a :SampleTube .
          :s4 :a :SampleTube .
          :rack2   :a                 :TubeRack ;
                   :contains          :tube1, :tube2, :tube3, :tube4 .          
          :tube1   :a                 :Tube ;
                   :location          "A1" ;
                   :sample_tube       :s1 .
          :tube2   :a                 :Tube ;
                   :location          "B1" ;
                   :sample_tube       :s2 .
          :tube3   :a                 :Tube ;
                   :location          "A1" ;
                   :sample_tube       :s3 .
          :tube4   :a                 :Tube ;
                   :location          "B1" ;
                   :sample_tube       :s4 .
        }
        @assets = SupportN3::parse_facts(facts)
        @rack2 = Asset.find_by(uuid: 'rack2')
        expect{@rack2.attributes_to_update}.to raise_exception
      end
    end
  end
end