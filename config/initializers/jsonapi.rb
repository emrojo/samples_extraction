JSONAPI.configure do |config|
  # :underscored_key, :camelized_key, :dasherized_key, or custom
  config.json_key_format = :underscored_key
  config.resource_key_type = :uuid

  config.default_page_size = 25
  config.maximum_page_size = 1000
end

# Disable cops as we want to match the original coding as closely as possible
# rubocop:disable all
# Monkey patch MySQL compatibility to default to no quoting
# Issue: https://github.com/cerebris/jsonapi-resources/issues/1369
# spec/requests/api/v1/assets_spec.rb will fail in absence of this fix

raise <<~EXCEPTION unless JSONAPI::Resources::VERSION == '0.10.7'
    JsonApi::Resources version has changed, please validate monkey patch in #{__FILE__}
    New source
    #{JSONAPI::ActiveRelationResource.method(:sql_field_with_alias).source}
  EXCEPTION

class JSONAPI::ActiveRelationResource
  # Change: Default value of quoted changed to false
  def self.sql_field_with_alias(table, field, quoted = false)
    Arel.sql("#{concat_table_field(table, field, quoted)} AS #{alias_table_field(table, field, quoted)}")
  end
end
# rubocop:enable all
