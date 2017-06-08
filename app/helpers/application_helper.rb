module ApplicationHelper
  def bootstrap_link_to(name = nil, options = nil, html_options = nil, &block)
    modified_options = {:class => 'btn btn-default'}
    modified_options.merge!(html_options) if html_options
    link_to(name, options, modified_options)
  end

  UNKNOW_ALIQUOT_TYPE = 'unknown-aliquot'

  def default_ontologies
    "@prefix : <#{url_to_asset('root-ontology.ttl')}#> .".html_safe
  end

  def traversable_predicate(predicate)
    ['contains'].include?(predicate)
  end

  def data_rack_display(facts)
    #return '' unless facts.first.class == Fact
    f = facts.select{|f| f.predicate == 'aliquotType'}.first
    if f
      return {:aliquot => {
        :cssClass => [(f.object || UNKNOW_ALIQUOT_TYPE), facts.select{|f2| f2.predicate == 'is'}.map do |f_is|
          [f_is.predicate, f_is.object].join('-')
        end].compact.join(' '),
        :url => ((f.class==Fact) ? asset_path(f.asset) : '')
        }}.to_json
    end

    unless facts.select{|f| f.predicate == 'contains'}.empty?
      return facts.select{|f| f.predicate == 'contains'}.map do |fact|
        [fact.object_asset, fact.object_asset.facts] if (fact.class == Fact) && (fact.object_asset)
      end.compact.reduce({}) do |memo, list|
        asset, facts = list[0],list[1]
        f = facts.select{|f| f.predicate == 'location'}.first
        unless f.nil?
          location = f.object
          f2 = facts.select{|f| f.predicate == 'aliquotType'}.first
          aliquotType = f2 ? f2.object : nil
          memo[location] = {:title => "#{asset.short_description}", :cssClass => aliquotType || UNKNOW_ALIQUOT_TYPE, :url => asset_path(asset)} unless location.nil?
        end
        memo
      end.to_json
    end

    return {
      :aliquot => {
        :cssClass => facts.select{|f| f.predicate == 'is'}.map do |f|
          "#{f.predicate}-#{f.object}"
        end.join(' '),
        :url => ''
      }
    }.to_json
  end

  def svg(name)
    name = 'TubeRack' if name == 'Plate'
    name = 'Tube' if name == 'SampleTube'

    Rails.application.assets["#{name.downcase}"].to_s.html_safe || "('#{name.downcase}.svg' not found)"
  end

  def svg_for_facts(facts)
    svg(facts.select{|f| f.predicate == 'a'}.pluck(:object).first)
  end

  def show_alert(data)
    @alerts = [] unless @alerts
    @alerts.push(data)
  end

  def trigger_alerts
    triggers = @alerts.map do |a|
      "<script type='text/javascript'>$(document).trigger('msg.display_error', #{a.to_json});</script>"
    end.join('\n').html_safe if @alerts
  end

end
