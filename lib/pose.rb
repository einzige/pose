require 'active_record'
require 'pose/query'
require 'pose/search'
require 'pose/static_api'
require 'pose/helpers'
require 'pose/activerecord_base_additions'
require 'pose/model_class_additions'
require 'pose/railtie' if defined? Rails
require 'pose/assignment'
require 'pose/word'

module Pose
end

ActiveRecord::Base.send :extend, Pose::ActiveRecordBaseAdditions
