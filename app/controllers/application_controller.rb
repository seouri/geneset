class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :subject_ids

  private
  
  def subject_ids
    @subject_ids = []
    @subject_ids = params[:ids].split(/,/).uniq.compact.reject {|id| id.blank? or id.match(/\D/)} if params[:ids].present?
    @ids = @subject_ids.join(",")
    @term = Subject.find(@subject_ids).map{|subject| subject.term + "[majr]"}.join(" AND ")
  end
end
