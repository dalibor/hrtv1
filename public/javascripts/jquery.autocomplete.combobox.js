(function( $ ) {
    $.widget( "ui.combobox", {
      _create: function() {
        var self = this,
          select = this.element.hide(),
          selected = select.children( ":selected" ),
          value = selected.val() ? selected.text() : "";
        var input = this.input = $( "<input>" )
          .insertAfter( select )
          .val( value )
          .autocomplete({
            delay: 0,
            minLength: 2,
            source: function( request, response ) {
              var matcher = new RegExp( $.ui.autocomplete.escapeRegex(request.term), "i" );
              var match = false;

              response( select.children( "option" ).map(function(i, value) {
                var text = $( this ).text();
                if ( this.value && ( !request.term || matcher.test(text) ) ) {
                  match = true;
                  return {
                    label: text.replace(
                      new RegExp(
                        "(?![^&;]+;)(?!<[^<>]*)(" +
                        $.ui.autocomplete.escapeRegex(request.term) +
                        ")(?![^<>]*>)(?![^&;]+;)", "gi"
                      ), "<strong>$1</strong>" ),
                    value: text,
                    option: this
                  };
                }
                // great "add new" solution from Nazar:
                // http://stackoverflow.com/questions/4690292/jquery-autocomplete-for-rails-application
                if (!match && i == select.children("option").size() -1) { //&& self.options.allow_new ) {
                  // remove any previous selected
                  select.children( ":selected" ).removeAttr("selected");
                  return {
                    label:'&lt;Create new <strong>'+ input.val() +'</strong>&gt;',
                    value: input.val(),
                    option: null
                  };
                }
              }));
            },
            select: function( event, ui ) {
              if(ui.item.option){
                ui.item.option.selected = true;
              }else{ // we clicked Create New
                select.children("option").val("-1") = $(this).val()
              };
              self._trigger( "selected", event, {
                item: ui.item.option
              });
            },
            change: function( event, ui ) {
              if ( !ui.item ) {
                var matcher = new RegExp( "^" + $.ui.autocomplete.escapeRegex( $(this).val() ) + "$", "i" ),
                  valid = false;
                select.children( "option" ).each(function() {
                  if ( $( this ).text().match( matcher ) ) {
                    this.selected = valid = true;
                    return false;
                  }
                });
                if ( !valid ) {
                  // Trigger the event for value not found
                  $(select).trigger('autocompletenotfound', $(this).val());

                  // remove invalid value, as it didn't match anything
                  $( this ).val( "" );
                  select.val( "" );
                  input.data( "autocomplete" ).term = "";
                  return false;
                }
              }
            }
          })
          .addClass( "ui-widget ui-widget-content ui-corner-left" );

        input.data( "autocomplete" )._renderItem = function( ul, item ) {
          return $( "<li></li>" )
            .data( "item.autocomplete", item )
            .append( "<a>" + item.label + "</a>" )
            .appendTo( ul );
        };
      },

      destroy: function() {
        this.input.remove();
        this.button.remove();
        this.element.show();
        $.Widget.prototype.destroy.call( this );
      }
    });
  })( jQuery );