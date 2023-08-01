class CreateHeronActivitiesView < ActiveRecord::Migration[5.1] # rubocop:todo Style/Documentation
  def up
    ActiveRecord::Base.connection.execute(<<~SQL)
      CREATE VIEW heron_activities_view AS
      SELECT
        IFNULL(
          supplier_name_fact.object,
          well_supplier_name_fact.object) AS "Supplier sample name",
        input_asset.barcode AS "Input barcode",
        output_asset.barcode AS "Output barcode",
        activity_types.name AS "Activity type",
        instruments.name AS "Instrument",
        kits.barcode AS "Kit barcode",
        kit_types.name AS "Kit type",
        ac.completed_at AS "Date",
        users.fullname AS "User",
        ac.id AS "_activity_id_"
      FROM activities AS ac
        LEFT OUTER JOIN asset_groups_assets AS aga ON aga.asset_group_id = ac.asset_group_id
        LEFT OUTER JOIN assets AS output_asset ON output_asset.id = aga.asset_id
        LEFT OUTER JOIN activity_types ON ac.activity_type_id = activity_types.id
        LEFT OUTER JOIN kits ON ac.kit_id = kits.id
        LEFT OUTER JOIN kit_types ON kits.kit_type_id = kit_types.id
        LEFT OUTER JOIN instruments ON ac.instrument_id = instruments.id
        LEFT OUTER JOIN facts AS supplier_name_fact ON supplier_name_fact.asset_id = output_asset.id AND supplier_name_fact.predicate = "supplier_sample_name"
        LEFT OUTER JOIN facts AS well_fact ON well_fact.asset_id = output_asset.id AND well_fact.predicate = "contains"
        LEFT OUTER JOIN facts AS well_supplier_name_fact ON well_supplier_name_fact.asset_id = well_fact.object_asset_id AND well_supplier_name_fact.predicate = "supplier_sample_name"
        LEFT OUTER JOIN assets AS input_asset ON input_asset.id = (
          SELECT object_asset_id FROM operations
          INNER JOIN steps ON steps.id = operations.step_id
          WHERE operations.predicate = 'transferredFrom' AND steps.activity_id = ac.id AND operations.object_asset_id IS NOT NULL
          ORDER BY operations.created_at ASC, operations.id ASC
          LIMIT 1
        )
        LEFT OUTER JOIN users ON users.id = (
          SELECT user_id FROM steps
          WHERE steps.activity_id = ac.id AND steps.user_id IS NOT NULL
          ORDER BY steps.created_at, steps.id DESC
          LIMIT 1
        )
      WHERE
        ac.state = 'finish'
        AND (supplier_name_fact.id IS NOT NULL OR well_supplier_name_fact.id IS NOT NULL)
        AND activity_types.name IN ('CGAP Heron Extraction 500ul - 16ul',
      'CGAP Heron Extraction 500ul - 24ul',
      'Illumina Extraction',
      'DNAP Heron Extraction 500ul - 24ul',
      'CGAP Heron Extraction 200ul - 24ul',
      'Heron R&D Extraction')
    SQL
  end

  def down
    ActiveRecord::Base.connection.execute('DROP VIEW IF EXISTS heron_activities_view')
  end
end
