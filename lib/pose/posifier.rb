module Pose
  module Posifier
    extend ActiveSupport::Concern

    module ClassMethods
      def posify
        include Pose
      end
    end
  end
end
ActiveRecord::Base.send :include, Pose::Posifier
