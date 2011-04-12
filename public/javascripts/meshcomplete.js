$(function() {
  //$("#meshcomplete-box").append('<input id="meshcomplete" />').append('<span id="meshcomplete-clear" title="Clear search">&times;</span>').append('<input type="hidden" id="meshcomplete-selected-ids"/>');
  $("#meshcomplete").attr("value","").attr("size", 5);
  $("#meshcomplete-box").click(function(){  
    $("#meshcomplete").focus(); 
  });
  $("#meshcomplete-box .remove").live("click", function(){  
    var removed_id = $(this).parent().attr("data-meshcomplete-id");
    var selected_ids = $("#meshcomplete-selected-ids").attr("value");
    selected_ids = selected_ids.replace(new RegExp("," + removed_id), "");
    $("#meshcomplete-selected-ids").attr("value", selected_ids);
    $(this).parent().remove();
    if ($("#meshcomplete-box .operator").length >= $("#meshcomplete-box .selected").length) {
      $("#meshcomplete-box .operator").last().remove();
    }
    if ($("#meshcomplete-box .selected").length > 0) {
      $.get("/meshcomplete-update", { ids: selected_ids },
        function(data) {
          $("#meshcomplete-update").html(data);
        }
      );
    } else {
      $("#meshcomplete-update").html("");
    }
  });
  $("#meshcomplete-clear").live("click", function(){  
    $("#meshcomplete-box .selected").each(function(index) { $(this).remove() });
    $("#meshcomplete-box .operator").each(function(index) { $(this).remove() });
    $("#meshcomplete-selected-ids").attr("value", "");
    $("#meshcomplete").attr("value", "");
    $("#meshcomplete-update").html("");
  });
  $("#meshcomplete").bind('keyup keydown blur update', function(){
    if($("#meshcomplete").attr("size") < $("#meshcomplete").val().length){
      size = $("#meshcomplete").val().length + 5;
      $("#meshcomplete").attr("size",size);
    }
  });
  $("#meshcomplete").autocomplete({
    source: "/meshcomplete",
    select: function(e, ui) {
      var selected = ui.item.value,
          span = $("<span>").addClass("selected").text(selected).attr("data-meshcomplete-id", ui.item.id);
      if ($("#meshcomplete-box .selected").length > 0) {
        var operator = $("<span>").addClass("operator").attr({
            }).html("AND").toggle(
              function () {
                $(this).html("OR");
              },
              function () {
                $(this).html("NOT");
              },
              function () {
                $(this).html("AND");
              }
            );
        operator.insertBefore("#meshcomplete");
      }
      var a = $("<a>").addClass("remove").attr({
              href: "javascript: return false;",
              title: "Remove " + selected
          }).html("&times;").appendTo(span);
      span.insertBefore("#meshcomplete");
      $("#meshcomplete").attr("value","").attr("size", 5);
      var selected_ids = $("#meshcomplete-selected-ids").attr("value").split(",");
      selected_ids.push( ui.item.id );
      $("#meshcomplete-selected-ids").attr("value", selected_ids.join(","));
      $.get("/meshcomplete-update", { ids: selected_ids.join(",") },
        function(data) {
          $("#meshcomplete-update").html(data);
        }
      );
      return false;
    },
    focus: function() {
      return false;
    }
  })
  .data( "autocomplete" )._renderItem = function( ul, item ) {
    var re_label = new RegExp("^" + this.term, "i");
    var re_entries = new RegExp("(^|\| )" + this.term, "gi");
    var label = item.label.replace(re_label, "<span class='matched'>$&" + "</span>");
    var entries = item.entries.join(" | ").replace(re_entries, "<span class='matched'>" + "$&" + "</span>");
    return $( "<li></li>" )
  	  .data( "item.autocomplete", item )
  	  .append("<a>" + label + "<div class='entry_term'>" + entries + "</div>" + "</a>")
  		.appendTo( ul );
  };
});
