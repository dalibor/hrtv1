/**
    Project: Validate Classification Tree
    Author:  Glenn Roberts (Based on work by Lewis Jenkins in his Collapsible Checkbox Tree jQuery Plugin)

    License:
        This code currently available for use in all personal or
        commercial projects under both MIT and GPL licenses. This means that you can choose
        the license that best suits your project and use it accordingly.
*/

(function($) {
  $.fn.validateClassificationTree = function(options) {
    var defaults = {
      checkParents : true, // When checking a box, all parents are checked
      checkChildren : false, // When checking a box, all children are checked
      uncheckChildren : true, // When unchecking a box, all children are unchecked
      initialState : 'default' // Options - 'expand' (fully expanded), 'collapse' (fully collapsed) or default
    };

    var options = $.extend(defaults, options);

    this.each(function() {

      var $root = this;

      // Text focus function - check the associated checkbox
      $("input[type='text']", $(this)).focus(function(){

        // TODO: delegate to checkboxTree js
        //
        // Show immediate children  of checked
        $("> ul", $(this).closest("li")).removeClass('hide');
        // Update the tree
        $("> span.collapsed", $(this).closest("li")).removeClass("collapsed").addClass("expanded").html('-');
        // Check parents if necessary
        if (defaults.checkParents) {
          $(this).parents("li").find("input[type='checkbox']:first").attr('checked', true);
        }
        // Check children if necessary
        if (defaults.checkChildren) {
          $(this).closest("li").find("input[type='checkbox']").attr('checked', true);
          // Show all children of checked
          $("ul", $(this).closest("li")).removeClass('hide');
          // Update the tree
          $("span.collapsed", $(this).closest("li")).removeClass("collapsed").addClass("expanded").html('-');
        }
      });

      // Check percentages on lost focus
      $("input[type='text'][id$=_percentage]", $(this)).blur(function(){
        if ($.trim($(this).val()) != ''){
          var $percentage = $.trim($(this).val()).replace(/,/g,'')
          // If I enter a bad percent, indicate an error
          if( isNaN($percentage) ) {
             alert("Percentage should be a number (with proper decimal formatting)");
          } else {
            var $pc_float = parseFloat($percentage)
            if ($pc_float > 100.0 || $pc_float < 0) {
              alert("Percentage should be between 0 and 100");
            } else {
               // check that this value doesnt tip our total percentage over 100 parent amount
               var sumPercentage = 0;
               parent            = $("input[type='text'][id$=percentage]:first", $(this).closest("li").closest("ul").closest("li"));
               parent_percentage = $.trim( parent.val() );
               sibling_percents  = ($(this).closest("li").closest("ul")).find("> li > div > div > input[type='text'][id$=_percentage]");
               sibling_percents.each(function(index) {

                 val = parseFloat( $.trim( $(this).val() ) )
                 if ( !isNaN(val) )
                   sumPercentage += val;
               });

               if( sumPercentage > 100 ){
                 alert( "Warning: child percentages (" + sumPercentage + "%) exceed 100%");
               } else if ( parent_percentage > 0 && (sumPercentage > parent_percentage) ){
                alert( "Warning: child percentages (" + sumPercentage + ") exceed parent amount (" + parent_percentage + "). Any percent you enter is multiplied by the total to get the amount. For instance if you enter 10% on the code above then 100% underneath, you will be putting more money under the code than above it, which is incorrect." );
              }
             }
          }
        }
      });

      // Check amounts on lost focus
      $("input[type='text'][id$=_amount]", $(this)).blur(function(){
        if ($.trim($(this).val()) != ''){
          var $amount = $.trim($(this).val()).replace(/,/g,'')
          // If I enter a bad percent, indicate an error
          if( isNaN($amount) ) {
             alert("Amount should be a number");
          } else {
            if (parseFloat($amount) < 0 ) {
              alert("Amount should be greater than zero");
            } else {
              // check that this value doesnt tip our total sum over our parent amount
              // get amounts on siblings
              var sumTotal      = 0;
              parent            = $("input[type='text'][id$=amount]:first", $(this).closest("li").closest("ul").closest("li"));
              parent_amount     = $.trim( parent.val() );
              sibling_amounts   = ($(this).closest("li").closest("ul")).find("> li > input[type='text'][id$=_amount]");
              sibling_amounts.each(function(index) {
                  val = parseFloat( $.trim( $(this).val() ) )
                  if ( !isNaN(val) )
                    sumTotal += val;
              });

              if( parent_amount > 0 && (sumTotal > parent_amount) ){
                alert( "Warning: child amounts (" + sumTotal + ") exceed parent amount (" + parent_amount + ")" );
              }
            }
          }
        }
      });


      // When losing focus, do some validation
      $("input[type='text']", $(this)).blur(function(){
        // If I enter a value in a parent, then indicate that children need entering
        if ($.trim($(this).val()) != ''){
          //$("input[type='text'][id$=amount]:first", $(this).parent("li").parent("ul").parent("li")).val('sup'); // children, not all descendants
          //($(this).parent("li").parent("ul")).find("> li > input[type='text'][id$=_amount]").val('sib'); // children, not all descendants
          //$("> ul ", $(this).parent("li")).addClass('incomplete'); // siblings
        }
      });
    });
    return this;
  };
})(jQuery);
