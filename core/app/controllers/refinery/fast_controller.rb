module Refinery
  class FastController < ActionController::Base
    protect_from_forgery with: :exception

    def message
      render :partial => '/refinery/message', :layout => false
    end

  end
end
