document.addEventListener("DOMContentLoaded", function(event) {


  // vanilla js ajax
  var distributor_selector=document.querySelector("#ajax_add_distributor");
  if(distributor_selector) {
    distributor_selector.addEventListener('change', function(){
      var http = new XMLHttpRequest();
      var distributors_list=document.querySelector("#ajax_distributors");
      var messages=document.querySelector(".messages");

      http.addEventListener("loadstart", function startProgress() {
        distributors_list.innerHTML = "Cargando...";
      });

      http.addEventListener("progress", function onprogress(evt) {
        if(evt.lengthComputable) {
          messages.max = evt.total;
          messages.value = evt.loaded;
        }
      });

      http.addEventListener("abort", transferCanceled, false);
      http.addEventListener("error", transferFailed, false);

      http.addEventListener("load", function load(evt) {
        if(http.status == 200) {
          distributors_list.innerHTML = http.responseText;
          setFlash(messages, "Cambios en proveedores guardados con exito", "notice")
        } else {
          distributors_list.innerHTML = "Error: " + http.responseText;
          setFlash(messages, http.responseText, "error")
        }
        distributor_selector.value="";
      });

      var url = this.dataset.url + this.value;
      http.open("POST", url, true);
      http.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
      var params = this.dataset.csrfKey + "=" + encodeURIComponent(this.dataset.csrfToken);
      http.send(params);
    }, false);
  }

  function setFlash(parent, message, type) {
    parent.innerHTML = "";
    var flash = createElem("div", "⚫ " + message);
    flash.className += "flash flash_" + type + " bounceInDown";
    parent.appendChild(flash);
  }

  function transferFailed(evt) {
    alert("Error de transferencia.");
  }

  function transferCanceled(evt) {
    alert("Transferencia cancelada.");
  }

  el = document.querySelectorAll('.ajax_hide_on_click');
  for ( var i = 0; i < el.length; i++ ) {
      el[i].addEventListener("click", function(){
        this.classList.add('hide');
      }, false);
  }


  el = document.querySelectorAll('.ajax_hide_parent_on_click');
  for ( var i = 0; i < el.length; i++ ) {
      el[i].addEventListener("click", function(e){
        e.stopPropagation();
        e.preventDefault();
        var parent = get_parent(this, this.dataset.tag);
        parent.classList.add('hide');
        setTimeout(function(){
          parent.style.display = "none";
        },700)
      }, false);
  }

  // Find first ancestor of el with tagName
  // or undefined if not found
  function get_parent(el, tagName) {
    tagName = tagName.toLowerCase();
    do {
      el = el.parentNode;
      if (el.tagName.toLowerCase() == tagName) {
        return el;
      }
    } while (el.parentNode)
    return null;
  }

  $('.ajax_confirm').click(function(){
    var answer = confirm( $(this).data('confirm_message') );
    return answer
  });

  $('.ajax_hide_items').click(function(){
    $('.items').hide("slow");
  });


  $(".toggle_me").hide();
  $(".toggle_link").click(function(e) {
    $(this).next(".toggle_me").toggle('slow');
    $(this).toggleClass("current").focus();
  });


  $(".autoselect").focus().select();
  $('input[name=i_id]').attr('autocomplete','off');


  $("a.edit").focusin(function() {
    $(this).closest("tr").addClass('item_hover')
  }).focusout(function() {
    $(this).closest("tr").removeClass('item_hover')
  }).click(function(){
    $(this).closest("tr").removeClass('item_hover')
  });
  $(".ajax_item").click(function() {
    window.location.href = $(this).find("a").attr("href");
  });


  $(".flash.notice").parent().addClass('flash_notice');
  $(".flash").hover(function() { $(this).addClass('bounceOutUp') });

  setTimeout(function(){
    $(".flash_notice").addClass('bounceOutUp');
  },5000)

  setTimeout(function(){
    $(".flash_warning").addClass('bounceOutUp');
  },10000)


  // DOM manupulation demo
  function popupate_distributors_list(responseText) {
    var distributors_list=document.querySelector("#ajax_item_distributors");
    distributors_list.innerHTML = "";
    var json = JSON.parse(responseText);
    distributors_list.appendChild(createP("⚫ " + JSON.parse(json[i]).d_name));
  }
  function createP(text) {
    var p = document.createElement("p");
    p.appendChild( document.createTextNode(text) );
    return p;
  }
  function createElem(elem, text) {
    var e = document.createElement(elem);
    e.appendChild( document.createTextNode(text) );
    return e;
  }



  $('.edit_bulk').click(function(e) {
    e.preventDefault();
    e.stopPropagation();
    var target = $(this).closest('tr'), url = "/admin/bulks/" + e.target.dataset.b_id;
    $.ajax({
      type: 'GET',
      url: url,
      // data: { postVar1: 'theValue1', postVar2: 'theValue2' },
      beforeSend:function(){
        target.html('<td colspan="6" class="loading"><img src="/media/loading.gif" alt="Cargando..." /></td>');
      },
      success:function(data){
        target.html(data);
        $("[autofocus]").focus().select();
      },
      error:function(){
        $('#ajax_panel').html('<p class="error"><strong>Oops!</strong> Proba denuevo.</p>');
      }
    });
  });
  $('form').on('keyup','select[name=b_status]', function(e){
    if(e.keyCode == 13) {
      $(this).closest("form").submit();
    }
  });

  $('input[type=tel].number.positive').on({'focus': function(e){
      original = this.value;
    }, 'keyup': function(e){
      if( ~this.value.indexOf('-') ) {
        this.value = this.value.replace(/[\-]/g,'');
      }
      if( !is_number(this.value) ) {
        this.value = original;
      }
    }
  });

  $('form').on('keyup','#ajax_product_buy_cost', function(e){
    update_markup_and_sale_cost();
  });

  $('#ajax_product_price').on({'focus': function(e){
      original_price = document.getElementById("ajax_product_price").value;
    },
    'keyup': function(e){
      if (this.value.length > 0 && this.value != original_price) {
        update_markup_and_sale_cost();
        update_exact_price();
      }
    }
  });


  function is_number(value) {
    return parseFloat(value.replace(/[\,]/g,'.')) == Number(value.replace(/[\,]/g,'.'));
  }

  function as_number(value) {
    return Number(value.replace(/[\,]/g,'.'));
  }

  function update_markup_and_sale_cost() {
    buy_cost = document.getElementById("ajax_product_buy_cost");
    parts_cost = document.getElementById("ajax_product_parts_cost");
    materials_cost = document.getElementById("ajax_product_materials_cost");
    sale_cost = document.getElementById("ajax_product_sale_cost");
    ideal_markup = document.getElementById("ajax_product_ideal_markup");
    real_markup = document.getElementById("ajax_product_real_markup");
    price = document.getElementById("ajax_product_price");

    var full_real_markup = as_number(price.value) / ( as_number(buy_cost.value) + as_number(parts_cost.value) + as_number(materials_cost.value));
    var round_real_markup = Math.round(full_real_markup*1000)/1000;
    real_markup.value = round_real_markup;
    if (ideal_markup.value == "" || ideal_markup.value == 0 || ideal_markup.value == Infinity || ideal_markup.value == NaN) {
      ideal_markup.value = real_markup.value;
    }
    var full_sale_cost = as_number(buy_cost.value) + as_number(parts_cost.value) + as_number(materials_cost.value);
    var round_sale_cost = Math.round(full_sale_cost*1000)/1000;
    sale_cost.value = round_sale_cost;
  }

  function update_exact_price() {
    exact_price = document.getElementById("ajax_product_exact_price");
    price = document.getElementById("ajax_product_price");
    exact_price.value = price.value;
  }

  $('.ajax_void_item').click(function(e) {
    e.preventDefault();
    e.stopPropagation();
    var answer = confirm( $(this).data('confirm_message') );
    if( answer == false ) {
      return false;
    }
    var target = $(".ajax_response");
    var url = $(this).closest('form').attr("action");
    var csrf = $(this).siblings("input[name=csrf]").attr("value");
    var i_id = $(this).siblings("input[name=i_id]").attr("value");

    $.ajax({
      type: 'POST',
      url: url,
      data: { csrf: csrf },
      beforeSend:function(){
        target.html('<div class="loading"><img src="/media/loading.gif" alt="Cargando..." /></div>');
      },
      success:function(data){
        $(".flash").hide("slow");
        target.html(data);

        var base = $("td:contains("+i_id+")")
        base.parent("tr").hide("slow");
        var counter = base.closest("table").find(".counter");
        var counter_text = counter.html().trim();
        var counter_num = parseInt(counter_text, 10);
        counter.html( counter_text.replace(counter_num, counter_num-1) );
        $("[autofocus]").focus().select();
      },
      error:function(){
        target.html('<p class="error"><strong>Oops!</strong> Proba denuevo.</p>');
      }
    });
  });


});
