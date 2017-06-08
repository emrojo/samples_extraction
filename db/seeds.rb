# frozen_string_literal: true
# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

User.create(barcode: '1', username: 'admin', role: 'administrator')

require 'support_n3'

SupportN3.parse_file('lib/workflows/reracking.n3')

reracking_activity_type = ActivityType.last
kit_type = KitType.create(name: 'Re-Racking', activity_type: reracking_activity_type)
kit = Kit.create(barcode: '9999', kit_type: kit_type)
instrument = Instrument.create(barcode: '9999', name: 'Re-Racking')
instrument.activity_types << reracking_activity_type

SupportN3.parse_file('lib/workflows/qiacube.n3')

activity_type = ActivityType.last

kt = KitType.create(name: 'qiacube', activity_type: activity_type)

Kit.create(barcode: '1234', kit_type: kt)

instrument.activity_types << activity_type
