class GenesController < ApplicationController
  def index
    @genes = Gene.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @genes }
    end
  end

  def show
    @gene = Gene.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @gene }
    end
  end
