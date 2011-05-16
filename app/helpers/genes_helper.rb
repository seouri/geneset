module GenesHelper
  def pubmed_links(gene_id, term)
    rettype = ["docsum", "abstract", "citation", "uilist"]
    rettype.map{|r| link_to(r, pubmed_path(:gene_id => gene_id, :term => u(term), :rettype => r), :class => "pubmed_link", :target => "_blank")}.join(" ").html_safe
  end
end
