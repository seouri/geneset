class GenesController < ApplicationController
  def index
    @genes = Gene.limit(10)

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

  def top
    subject_ids = params[:ids].split(/,/).uniq.compact.reject {|id| id.blank?} if params[:ids].present?
    @genes = []
    if subject_ids.present?
      if subject_ids.size == 1
        @genes = GeneSubject.where(:subject_id => subject_ids.first).order("articles_count desc").limit(20).includes(:gene).map {|gs| gs.gene}
      else
        article_ids = ArticleSubject.select("article_id, count(*) subjects").where(:subject_id => subject_ids).group(:article_id).having("subjects=#{subject_ids.size}").map{|as| as.article_id}
        gene_ids = ArticleGene.where(:article_id => article_ids).group(:gene_id).select("gene_id, count(*) articles").order("articles desc").limit(20).map {|a| a.gene_id}
        @genes = Gene.find(gene_ids)
      end
    end
    render :layout => false
  end
end
