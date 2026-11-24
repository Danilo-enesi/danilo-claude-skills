(function (window, $, undefined) {


    /* Browser Built In Fix
    ------------------------------------------------------------ */

    if (typeof Array.prototype.forEach !== 'function') {
        Array.prototype.forEach = function (callback) {
            for (var i = 0; i < this.length; i++) {
                callback.apply(this, [this[i], i, this]);
            }
        };
    }


    /* Public functions
    ------------------------------------------------------------ */

    window.__ = function (key, replace = {}) {
        if(!window.front.translations){
            return '';
        }
    
        let translation = key.split('.').reduce((t, i) => t[i] || null, window.front.translations);
    
        for (var placeholder in replace) {
            translation = translation.replace(`:${placeholder}`, replace[placeholder]);
        }
    
        return translation;
    };


    /* jQuery
    ------------------------------------------------------------ */

    $.ajaxSetup({
        headers: {
            'X-CSRF-TOKEN': $('meta[name="csrf-token"]').attr('content')
        }
    });

    $.fn.serializeObject = function () {
        var o = {};
        var a = this.serializeArray();
        $.each(a, function () {
            if (o[this.name] !== undefined) {
                if (!o[this.name].push) {
                    o[this.name] = [o[this.name]];
                }
                o[this.name].push(this.value || '');
            } else {
                o[this.name] = this.value || '';
            }
        });
        return o;
    };

    $.fn.prepareTransition = function(){
        return this.each(function(){
            var el = $(this);
            // remove the transition class upon completion
            el.one('TransitionEnd webkitTransitionEnd transitionend oTransitionEnd', function(){
                el.removeClass('is-transitioning');
            });
    
            // check the various CSS properties to see if a duration has been set
            var cl = ["transition-duration", "-moz-transition-duration", "-webkit-transition-duration", "-o-transition-duration"];
            var duration = 0;
            $.each(cl, function(idx, itm){
                duration || (duration = parseFloat( el.css( itm ) ));
            });
    
            // if I have a duration then add the class
            if (duration != 0) {
                el.addClass('is-transitioning');
                el[0].offsetWidth; // check offsetWidth to force the style rendering
            };
        });
    };


    
    /*
     ============================================================
     BEERS CORE
     ============================================================
     */


    var Beers = new function () {
        var self = this;

        self.context = window.document;

        var options = {
            plugins: [
                'ajaxform',
                'ajaxcall',
                'animate',
                'box',
                'carousel',
                'gallery',
                'lazyload',
                'maxlength',
                'offcanvas',
                'popup',
                'qtyInput',
		        'readmore',
                'sameHeight',
                'scroll',
                'scrolled',
                'uiselect'
            ]
        };

        self.getValue = function (obj) {
            return (typeof obj === 'function') ? obj() : obj;
        };

        // PLUGIN BUILDER
        var pluginBuild = function (context, name) {
            var plugin = (Plugins.hasOwnProperty(name)) ? Plugins[name] : false;

            if (!plugin) {
                return false;
            }

            if (plugin.hasOwnProperty('autobuild') && self.getValue(plugin.autobuild) === true) {
                $(plugin.selector, context).each(function () {
                    if ($(this).data('beers-' + name)) {
                        return;
                    }
                    $(this).data('beers-' + name, new plugin.create(this));
                });
            } else if (plugin.hasOwnProperty('init') && typeof plugin.init === 'function') {
                plugin.init(context);
            }
        };

        // INIT
        self.init = function (data) {

            // OPTIONS PROCESS
            if (typeof data === 'object') {
                if (data.hasOwnProperty('context')) {
                    self.context = data.context;
                }
                if (data.hasOwnProperty('options')) {
                    $.extend(true, options, data.options);
                }
                if (data.hasOwnProperty('callable')) {
                    $(window).on('beers:initialized', data.callable);
                }
            }

            // READY
            $(self.context).ready(function () {
                // LOAD
                self.load(self.context);

                // GENERAL TRIGGER
                $(window).trigger('beers:initialized');
            });
        };

        // LOAD
        var loadGmap = true;
        self.load = function (context) {
            $('html').addClass('bee-loaded');

            // PLUGINS
            options.plugins.forEach(function (name) {
                pluginBuild(context, name);
            });
            
            // PLUGINS CONSENT
            if(loadGmap && $('[data-gmap]').length && typeof window.google === 'undefined'){   
                loadGmap = false;   
                if (typeof window.EPP !== 'undefined') {
                    window.EPP.loadScript('//maps.google.com/maps/api/js?key=' + window.front.google_api_key, function() {
                        pluginBuild(context, 'gmap');
                    }, '10003'); 
                } else {
                    $.getScript('//maps.google.com/maps/api/js?key=' + window.front.google_api_key, function() {
                        pluginBuild(context, 'gmap');
                    }, '10003'); 
                }
            }
            
            // GENERAL TRIGGER
            $(window).trigger('beers:loaded', [context]);
        };
    }();


    
    /*
     ============================================================
     EXTENSIONS / TOOLS
     ============================================================
     */
    
    // AJAXDOM
    Beers.ajaxdom = new function () {
        var domRefresh = function (e, types, notypes) {
            var selectors = [];
            if (types !== undefined && types) {
                $.each((typeof types === 'string') ? [types] : types, function (i, type) {
                    selectors.push('[data-ajaxdom="' + type + '"]');
                });
            } else if (notypes !== undefined && notypes) {
                $.each((typeof notypes === 'string') ? [notypes] : notypes, function (i, type) {
                    selectors.push('[data-ajaxdom][data-ajaxdom!="' + type + '"]');
                });
            } else {
                selectors.push('[data-ajaxdom]')
            }

            // var $elements = $(selectors.join(','));
            if (selectors.length) {
                $.ajax({
                    url: location.href,
                    dataType: 'html',
                    success: function (html) {
                        $.each(selectors, function (i, selector) {
                            $(selector).each(function () {
                                var tmp = $('<div></div>').append($.parseHTML(html)).find('[data-ajaxdom="' + $(this).attr('data-ajaxdom') + '"]');
                                $(this).html(tmp.html());
                                Beers.load(this);
                                $(window).trigger('Beers.ajax.dom.reloaded', this);
                            });
                        });
                    }
                });
            }
        };

        $(window).off('Beers.ajax.dom.reload', domRefresh);
        $(window).on('Beers.ajax.dom.reload', domRefresh);
    }();

    // AJAXLOAD
    Beers.ajaxload = function () {

        var ajaxLoad = function (context) {
            var self = this;
            var $context = $(context);
            var fns = {};

            // DATA
            if ($context.data('beers-ajaxload')) {
                return;
            }
            $context.data('beers-ajaxload', this);

            // STATUS
            var loading = false;

            // OPTIONS
            var options = {
                control: '[data-ajaxload-controls]',
                content: '[data-ajaxload-content]'
            };

            // CONTROL
            fns.control = function () {
                $(context).on('click', options.control + ' a', function (e) {
                    if (!e.isDefaultPrevented()) {
                        e.preventDefault();
                    }
                    fns.link(this, $(this).attr('href'));
                });
            };

            // LOADING
            fns.loading = function (action) {
                switch (action) {
                    case 'start':
                        if (loading === true) {
                            return false;
                        } else {
                            loading = true;
                            return true;
                        }
                        break;

                    case 'stop':
                        setTimeout(function () {
                            loading = false;
                        }, 50);
                        break;
                }
            };

            fns.transitionOut = function (transitionEnd) {
                var contents = $(options.content, context);
                var contents_count = contents.length;

                function transitionComplete() {
                    contents_count--;
                    if (contents_count === 0 && typeof transitionEnd === 'function') {
                        transitionEnd.call();
                    }
                }
                ;

                contents.each(function () {
                    var current = $(this);
                    var transition = current.data('ajaxload-transition') || false;
                    switch (transition) {
                        case 'csstransition':
                            current.addClass('bee-ajaxload-transition-out');
                            current.one(Beers.css.event.transitionEnd, function () {
                                transitionComplete();
                            });
                            break;

                        case 'fade':
                            current.fadeOut(function () {
                                transitionComplete();
                            });
                            break;

                        default:
                            transitionComplete();
                            break;
                    }
                });
            };

            fns.replace = function (contents) {
                $(options.content, context).each(function () {
                    var current = $(this);
                    var content = contents.shift();
                    Beers.load(content);

                    var transition = content.data('ajaxload-transition') || false;
                    switch (transition) {
                        case 'csstransition':
                            content.addClass('bee-ajaxload-transition-out');
                            break;

                        case 'fade':
                            content.hide();
                            break;
                    }

                    current.replaceWith(content);
                });
            };

            fns.transitionIn = function (transitionEnd) {
                var contents = $(options.content, context);
                var contents_count = contents.length;

                function transitionComplete() {
                    contents_count--;
                    if (contents_count === 0 && typeof transitionEnd === 'function') {
                        transitionEnd.call();
                    }
                }
                ;

                contents.each(function () {
                    var current = $(this);
                    var transition = current.data('ajaxload-transition') || false;

                    switch (transition) {
                        case 'csstransition':
                            setTimeout(function () {
                                current.addClass('bee-ajaxload-transition-in');
                                current.one(Beers.css.event.transitionEnd, function () {
                                    current.removeClass('bee-ajaxload-transition-out bee-ajaxload-transition-in');
                                    transitionComplete();
                                });
                            }, 5);
                            break;

                        case 'fade':
                            current.fadeIn(function () {
                                transitionComplete();
                            });
                            break;

                        default:
                            transitionComplete();
                            break;
                    }
                });
            };

            // LOAD
            fns.load = function (url, callback) {
                if (Beers.location.isCurrent(url) || !fns.loading('start')) {
                    return;
                }

                $.get(url, function (source_html) {
                    var source = $('<div />', {html: source_html}).html();

                    var contents = [];
                    $(options.content, source).each(function () {
                        contents.push($(this));
                    });

                    fns.transitionOut(function () {
                        fns.replace(contents);
                        fns.transitionIn(function () {
                            fns.loading('stop');
                            $(window).trigger('beers:ajaxload.complete');
                        });
                    });

                    if (typeof callback === 'function') {
                        callback(url, source_html);
                    }
                }, 'html');
            };

            // LINK
            fns.link = function (element, url) {
                fns.load(url, function (url, html) {
                    var data = {
                        beersAjaxloadState: true,
                        title: html.match(/<title[^>]*>([^<]+)<\/title>/)[1]
                    };
                    Beers.history.push(url, data);
                    $(window).trigger('beers:ajaxload.success', [element]);
                });
            };

            // INIT
            fns.control();

            // HISTORY
            if (!Beers.history.state.is('beersAjaxloadState')) {
                Beers.history.replace({
                    beersAjaxloadState: true
                });
            }
            $(window).on('beers:history.pop', function (e) {
                if (!e.isDefaultPrevented() && Beers.history.state.is('beersAjaxloadState')) {
                    window.document.title = window.history.state.title;
                    var path = Beers.location.fullpath;
                    fns.load(path);
                }
            });
        };

        $(window).on('beers:initialized', function () {
            new ajaxLoad(window.document);
        });

    }();

    // CALLBACKS
    var canBodyScroll = true;
    var canBodyScrollTimeout = false;
    Beers.callbacks = new function () {
        var self = this;

        self.fire = function (method, options, context) {
            if (typeof this.fn[method] === 'function') {
                return this.fn[method].call(context, options);
            } else {
                throw 'Beers.callbacks: Method "' + method + '" doesn\'t exists';
            }
        };

        self.fireList = function (list, context) {
            var self = this;
            $.each(list, function (i, item) {
                if(item.hasOwnProperty('method')){
                    var method = item.method;
                    var options = item.options;
                } else {
                    var method = item[0];
                    var options = item[1];
                }
                self.fire(method, options, context);
            });
        };

        self.fn = {
            'ajax.dom.reload': function (options) {
                if (options && options.ids !== undefined) {
                    $(window).trigger('Beers.ajax.dom.reload', [options.ids]);
                } else if (options && options.noids !== undefined) {
                    $(window).trigger('Beers.ajax.dom.reload', [false, options.noids]);
                } else {
                    $(window).trigger('Beers.ajax.dom.reload');
                }
            },

            /* Alert */
            "alert": function (options) {
                if (typeof options.message === 'undefined') {
                    return;
                }
                new Beers.dialog({
                    content: options.message,
                    className: (typeof options.className !== 'undefined') ? options.className : undefined
                });
            },
            "alert.noclose": function (options) {
                if (typeof options.message === 'undefined') {
                    return;
                }
                new Beers.dialog({content: options.message, close: false, buttons: []});
            },
            "alert.inline": function (options) {
                if (typeof options.message === 'undefined') {
                    return;
                }

                // WRAPPER
                var alert = $('[data-alert-inline]', this);
                if (!alert.length) {
                    return;
                }

                var offset_top = alert.data('offset-top') || 100;

                // TEMPLATE
                var tpl = '<div class="alert alert-{type}"><span class="msg">{message}</span></div>';
                var html = tpl.replace('{type}', options.type).replace('{message}', options.message);

                // SHOW
                function show() {
                    alert.html(html);
                    alert.show();
                    var scroll = (typeof options.scrollForce !== 'undefined' && options.scrollForce === true) || (Beers.view.min('md') && !alert.closest('[data-bee-noscroll]').length);
                    if (scroll) {
                        var scroller = $('html,body');
                        if (alert.closest('.bee-dialog').length) {
                            scroller = alert.closest('.bee-dialog');
                        }
                        if (alert.closest('[data-scroll-context]').length) {
                            scroller = alert.closest('[data-scroll-context]');
                        }
                        scroller.animate({scrollTop: alert.offset().top - scroller.offset().top - offset_top}, 400);
                    }
                }

                if (alert.is(':visible')) {
                    alert.fadeOut(show);
                } else {
                    show();
                }
            },
            "alert.inline.remove": function (options) {
                $('[data-alert-inline]', this).fadeOut(function () {
                    $(this).empty();
                });
            },

            /* Dialog */ 
            "dialog": function (options) {
                new Beers.dialog(options);
            },
            "dialog.close": function (options) {
                Beers.dialogCloseAll();
            },

            /* Notify */
            "notify": function (options) {

                // WRAPPER
                var wrapper = ($('.bee-notify-wrapper').length) ? $('.bee-notify-wrapper') : $('<div />', {'class': 'bee-notify-wrapper', html : ''}).appendTo('body');

                if (options === false) {
                    wrapper.remove();
                }

                if (typeof options.message === 'undefined') {
                    return;
                }

                // NOTIFICA
                var tpl = '<div class="alert alert-{type}"><span class="msg">{message}</span><button class="bee-notify-close"></button></div>';
                var notify_html = tpl.replace('{type}', options.type).replace('{message}', options.message);
                var notify = $(notify_html).appendTo(wrapper);

                // CHIUSURA
                var notify_close = function () {
                    notify.fadeOut(function () {
                        $(this).remove();
                        if (!wrapper.children().length) {
                            wrapper.remove();
                        }
                    });
                };
                $(notify).on('click', notify_close);

                // CHIUSURA AUTOMATICA
                if (options.time === undefined) {
                    options.time = 1500;
                }

                if (options.time > 0) {
                    var notify_timeout = false;
                    notify.on('mouseenter', function () {
                        clearTimeout(notify_timeout);
                    });
                    notify.on('mouseleave', function () {
                        notify_timeout = setTimeout(notify_close, options.time);
                    });
                    notify_timeout = setTimeout(notify_close, options.time);
                }

                // OUTPUT
                setTimeout(function() {
                    notify.addClass('bee-notify-in');
                }, 20);
            },

            /* Popup */
            "popup": function(options) {
                if (typeof options.url === 'undefined') {
                    return;
                }

                var width = options.width || 800;
                var height = options.height || 600;
                var left = (screen.width - width) / 2;
                var top = (screen.height - height) / 2;
                window.open(options.url, options.title || '', 'scrollbars=no,resizable=yes, width=' + width + ',height=' + height + ',left=' + left + ',top=' + top + ',status=no,location=no,toolbar=no');
            },

            /* Form */
            "form.error": function(options){
                var form = this;
                
                if(!options || typeof options.field === undefined){
                    return;
                }
            
                // Input
                var input = $('[name="' + options.field + '"]:input', this);
                if(!input.length){    
                    return Beers.callbacks.fire('alert.inline', {message: options.message, type: 'warning'}, form);
                } 

                // Error container
                var errorContainer = input;
                if(!input.is(':visible')){    
                    errorContainer = input.parent();
                }  
                if(input.is('[data-uiselect]')){    
                    errorContainer = input.parent().find('.select2');
                }  

                // Add Error
                errorContainer.addClass('bee-error');
                if(typeof options.message !== undefined){
                    $('<div class="bee-error-message" />').html(options.message).insertAfter(errorContainer).css('top', errorContainer.position().top + errorContainer.outerHeight());
                }

                // Remove error on change
                input.on('change', function() {
                    errorContainer.removeClass('bee-error');
                    $('.bee-error-message', errorContainer.parent()).remove();
                });

                // Scroll if not in view
                if(!Beers.view.isElementInView(errorContainer) && canBodyScroll){
                    canBodyScroll = false;
                    $('html,body').animate({scrollTop: errorContainer.offset().top - (($(window).height() - errorContainer.height()) / 2)}, 500);
                    clearTimeout(canBodyScrollTimeout);
                    canBodyScrollTimeout = setTimeout(function() {
                        canBodyScroll = true;
                    }, 200);
                }
                input.focus();
            },
            "form.errors": function(options) {
                $('.bee-error', context).removeClass('bee-error');
                $('.bee-error-message', context).remove();

                var context = this;
                $.each(options, function(i, field){
                    Beers.callbacks.fire('form.error', field, context);
                });
            },
            "form.data": function (options) {
                var form = $(this);
                $.each(options, function (key, value) {
                    var input = $('[name="' + key + '"]:input', form);

                    if (input.length) {
                        input.val(value);
                    }
                });
            },
            "form.reset": function () {
                $(this)[0].reset();
                $(':input', this).not('[data-no-reset],[type="checkbox"],[type="radio"],[type="hidden"]').val('');

                if (typeof window.grecaptcha !== 'undefined') {
                    window.grecaptcha.reset();
                }
            },
            "form.submit": function () {
                $(this).data('ajaxform-disable', true);
                $(this).trigger('submit');
            },
            "form.validatorErrors": function(options) {
                var form = this;

                // Reset errori
                $(':input.is-invalid').removeClass('is-invalid');
                $('.invalid-feedback', form).remove();

                var globalMessages = [];

                // Ciclo errori
                if(typeof options.messages !== 'undefined'){
                    $.each(options.messages, function(name, messages) {
                        var input = $('[name=' + name + ']', form);
                        $.each(messages, function(i, message){
                            if(input.length) {
                                input.addClass('is-invalid');
                                input.after('<div class="invalid-feedback">' + message + '</div>');
                            } else {
                                globalMessages.push(message);
                            }
                        });
                    });
                }

                if(globalMessages.lenght){
                    bootbox.alert({
                        message: globalMessages.join('<br />')
                    });
                }
            },

            /* Location */
            "location": function (options) {
                if (typeof options.location === 'undefined') {
                    return;
                }
                if (typeof options.delay !== 'undefined') {
                    setTimeout(function(){
                        Beers.location.redirect(options.location);
                    }, options.delay);
                } else {
                    Beers.location.redirect(options.location);
                }
            },
            "history.push": function(options) {
                if (!options || typeof options.url === 'undefined') {
                    return;
                }
                Beers.history.push(options.url, options.data || {});
            },
            "reload": function () {
                Beers.location.reload();
            },

            /* jQuery Functions */
            "addClass": function (options){
                if (typeof options.selector === 'undefined' || typeof options.class === 'undefined') {
                    return;
                }
                $(options.selector).addClass(options.class);
            },
            "fadeIn": function (options) {
                $(options.selector, this).fadeIn();
            },
            "fadeOut": function (options) {
                $(options.selector, this).fadeOut();
            },
            "focus": function (options) {
                $(options, this).focus();
            },
            "hide": function (options) {
                $(options, this).hide(100);
            },
            "html": function (options) {
                $(options.selector, this).html(options.html);
            },
            "removeClass": function (options){
                if (typeof options.selector === 'undefined' || typeof options.class === 'undefined') {
                    return;
                }
                $(options.selector).removeClass(options.class);
            },
            "text": function(options){
                $(options.selector, this).text(options.text);
            },
            "post": function(options){
                Beers.ajax({
                    url: options.url,
                    data: options.data
                });
            },
            "print": function(options){
                window.print();
            },
            "remove": function(options){
                $(options.selector, this).remove();
            },
            "scrolltop": function(options){
                $(window).scrollTop(0);
            },
            "scrollto": function(options){
                if (typeof options.target === 'undefined') {
                    return;
                }
                
                var mt = options.margintop || 100;
                var context = options.context || window.document
                var top = ($(options.target, context).length) ? $(options.target, context).offset().top : false;

                if (top !== false) {
                    if(context == window.document){
                        context = 'html,body';
                    }
                    $(context).animate({scrollTop: top - mt}, 800);
                }
            }
        };
    }();

    // CSS
    Beers.css = new function () {

        var supports = {
            'animationEnd': {
                "animation": "animationend",
                "OAnimation": "oAnimationEnd",
                "MozAnimation": "animationend",
                "WebkitAnimation": "webkitAnimationEnd"
            },
            'transitionEnd': {
                "transition": "transitionend",
                "OTransition": "oTransitionEnd",
                "MozTransition": "transitionend",
                "WebkitTransition": "webkitTransitionEnd"
            }
        };

        function detect(name) {
            var t, el = document.createElement("fakeelement");
            for (t in supports[name]) {
                if (el.style[t] !== undefined) {
                    return supports[name][t];
                }
            }
        }
        ;

        this.event = {
            'animationEnd': detect('animationEnd'),
            'transitionEnd': detect('transitionEnd')
        };
    }();

    // DEVICE
    Beers.device = new function () {
        // Touch
        $('html').addClass('no-touch');

        $(window).on('beers:device.touch', function () {
            $('html').removeClass('no-touch').addClass('is-touch');
        });

        var supportsTouch = 'ontouchstart' in window || navigator.msMaxTouchPoints;
        if (supportsTouch) {
            $(window).trigger('beers:device.touch');
        }

        // WebP
        if(window.localStorage.getItem('bee:webpsupport') === null){
            function canUseWebP() {
                var elem = document.createElement('canvas');
            
                if (!!(elem.getContext && elem.getContext('2d'))) {
                    // was able or not to get WebP representation
                    return elem.toDataURL('image/webp').indexOf('data:image/webp') == 0;
                }
            
                // very old browser like IE 8, canvas not supported
                return false;
            }
            window.localStorage.setItem('bee:webpsupport', canUseWebP() ? 'y' : 'n');
        }
        $('html').addClass(window.localStorage.getItem('bee:webpsupport') == 'y' ? 'is-webp' : 'no-webp');
    }();

    // EVENTS
    Beers.events = new function () {

        // RESIZE END
        var resizeEndTimeout = false;
        $(window).on('resize', function () {
            clearTimeout(resizeEndTimeout);
            resizeEndTimeout = setTimeout(function () {
                $(window).trigger('beers:resize.end');
            }, 50);
        });
    }();

    // HISTORY
    Beers.history = new function () {
        var self = this;

        var o = {
            state: (typeof window.history.pushState === 'undefined') ? false : true,
            pop: $.noop
        };

        var fns = {};


        /* STATE ---------------------------------------------------- */

        setTimeout(function () {
            $(window).on('popstate', function () {
                $(this).trigger('beers:history.change');
                $(this).trigger('beers:history.pop');
            });
        }, 500);


        /* PRIVATE -------------------------------------------------- */

        // Initialize
        fns.init = function () {
            self.replace();
        };


        /* PUBLIC -------------------------------------------------- */

        // Replace state
        self.replace = function (url, data) {
            if (!o.state) {
                return false;
            }

            if (typeof url === 'object') {
                data = url;
                url = false;
            }

            var url = (url) ? url : Beers.location.fullpath;

            var data = $.extend({
                title: window.document.title
            }, data, {
                beersHistoryState: true
            });

            window.history.replaceState(data, data.title, url);
            $(window).trigger('beers:history.change');
            $(window).trigger('beers:history.replace');
        };

        // Push state
        self.push = function (url, data) {
            if (!o.state) {
                return false;
            }

            var data = $.extend({}, data, {
                beersHistoryState: true
            });

            if (data.hasOwnProperty('title')) {
                window.document.title = data.title;
            }

            window.history.pushState(data, window.document.title, url);
            $(window).trigger('beers:history.change');
            $(window).trigger('beers:history.push');
        };

        // State
        self.state = {
            get: function (property) {
                var state = {};

                if (o.state && typeof window.history.state !== 'undefined' && window.history.state) {
                    state = window.history.state;
                }

                if (typeof property !== 'undefined') {
                    state = state.hasOwnProperty(property) ? state[property] : undefined;
                }

                return state;
            },
            is: function (property) {
                return self.state.get(property) === true;
            }
        };


        /* INIT -------------------------------------------------- */
        $(window).on('beers:initialized', function () {
            fns.init();
        });
    }();

    // LOCATION
    Beers.location = new function () {
        var self = this;

        // Init
        var init = function () {
            self.protocol = window.location.protocol;
            self.host = window.location.hostname;
            self.port = window.location.port;
            self.path = window.location.pathname;
            self.query = (window.location.search) ? window.location.search.substr(1) : '';
            self.hash = (window.location.hash) ? window.location.hash.substr(1) : '';
            self.queryParams = self.decodeQuery(self.query);
            self.fullpath = self.getPath();
            self.href = window.location.href;
        };

        // Reload
        self.reload = function () {
            window.location.reload();
        };

        // Redirect
        self.redirect = function (url) {
            window.top.location = url;
        };

        // Path
        self.getPath = function (query, hash) {
            var query = self.getQuery(query);
            var hash = self.getHash(hash);
            return self.path + query + hash;
        };
        self.makePath = function (query, hash) {
            var query = self.makeQuery(query);
            var hash = self.makeHash(hash);
            return self.path + query + hash;
        };

        // Query
        self.getQuery = function (params) {
            var params = $.extend({}, self.queryParams, params);
            return self.makeQuery(params);
        };
        self.makeQuery = function (params) {
            $.each(params, function (i, val) {
                if (!val) {
                    delete params[i];
                }
            });
            var query = $.param(params);
            return (query) ? '?' + query : '';
        };

        // Hash
        self.getHash = function (hash) {
            if (!hash) {
                hash = self.hash;
            }
            return self.makeHash(hash);
        };
        self.makeHash = function (hash) {
            return (hash) ? '#' + hash : '';
        };

        // Decode
        self.decodeUri = function (str) {
            return decodeURIComponent(str.replace(/\+/g, " "));
        };
        self.decodeQuery = function (query) {
            var re = /([^&=]+)=?([^&]*)/g;
            var params = {}, e;
            while (e = re.exec(query)) {
                var k = self.decodeUri(e[1]),
                        v = self.decodeUri(e[2]);
                if (k.substring(k.length - 2) === '[]') {
                    k = k.substring(0, k.length - 2);
                    (params[k] || (params[k] = [])).push(v);
                } else {
                    params[k] = v;
                }
            }
            return params;
        };

        // Check
        self.isCurrent = function (url) {
            return (url === self.href);
        };

        $(window).on('beers:history.change', init);
        init();
    }();

    // MSIE DETECT
    Beers.msiedetect = new function () {

        var getVersion = function () {
            var ua = window.navigator.userAgent;

            var msie = ua.indexOf('MSIE ');
            if (msie > 0) {
                // IE 10 or older => return version number
                return parseInt(ua.substring(msie + 5, ua.indexOf('.', msie)), 10);
            }

            var trident = ua.indexOf('Trident/');
            if (trident > 0) {
                // IE 11 => return version number
                var rv = ua.indexOf('rv:');
                return parseInt(ua.substring(rv + 3, ua.indexOf('.', rv)), 10);
            }

            var edge = ua.indexOf('Edge/');
            if (edge > 0) {
                // Edge (IE 12+) => return version number
                return parseInt(ua.substring(edge + 5, ua.indexOf('.', edge)), 10);
            }

            // other browser
            return false;
        };
        var version = getVersion();
        if (version !== false) {
            $('html').addClass('is-msie is-msie-' + version);
        }
    }();

    // VIEW
    Beers.view = new function () {
        var self = this;

        var views = {
            xxs: [1, 0, 575],
            xs: [1, 576, 767],
            sm: [2, 768, 991],
            md: [3, 992, 1199],
            lg: [4, 1200, 0]
        };

        var last = false;
        var current = false;

        var init = function () {
            $(window).on('resize', $.proxy(self.detect, self));
            self.detect();
        };

        self.detect = function () {
            var w = $(window).width();
            $.each(views, function (n, o) {
                if ((o[1] === 0 || w >= o[1]) && (o[2] === 0 || w <= o[2])) {
                    current = o[0];
                    return false;
                }
            });

            if(last && last != current){
                $(window).trigger('beers:view.change');
            }
            last = current;

            return current;
        };

        self.current = function () {
            var result = false;
            $.each(views, function (name, val) {
                if (current == val[0]) {
                    result = name;
                    return false;
                }
            });
            return result;
        };

        self.is = function () {
            var result = false;

            $.each(arguments, function (i, v) {
                if (typeof views[v] !== 'undefined' && views[v][0] === current) {
                    result = true;
                    return false;
                }
            });

            return result;
        };

        self.not = function () {
            return !this.is.apply(this, arguments);
        };
        
        self.min = function (v) {
            if (typeof views[v] !== 'undefined' && views[v][0] <= current) {
                return true;
            }
            return false;
        };

        self.max = function (v) {
            if (typeof views[v] !== 'undefined' && views[v][0] >= current) {
                return true;
            }
            return false;
        };

        self.isElementInView = function (element, fullyInView) {
            var pageTop = $(window).scrollTop();
            var pageBottom = pageTop + $(window).height();
            var elementTop = $(element).offset().top;
            var elementBottom = elementTop + $(element).height();
    
            if (fullyInView === true) {
                return ((pageTop < elementTop) && (pageBottom > elementBottom));
            } else {
                return ((elementTop <= pageBottom) && (elementBottom >= pageTop));
            }
        }

        init();
    }();
    

    // PAGE LOADER
    var BeersPageLoaderTimeout = false;
    Beers.pageLoader = function(status) {
        if(status === true){
            clearTimeout(BeersPageLoaderTimeout);
            BeersPageLoaderTimeout = setTimeout(function() {
                $('[data-page-loader]').addClass('d-flex');
                setTimeout(function() {
                    $('html').addClass('bee-loading');
                }, 20);
            }, 200);
    
        } else {
            clearTimeout(BeersPageLoaderTimeout);
            setTimeout(function() {
                $('html').removeClass('bee-loading');
                $('[data-page-loader]').removeClass('d-flex');
            }, 400);
        }
    };

    // AJAX
    Beers.ajax = function (options) {
        Beers.pageLoader(true);
        // CALLBACKS DEFAULTS
        var callbacks = {
            success: function (r) {
                Beers.pageLoader(false);

                if (typeof r.callbacks !== 'undefined') {
                    Beers.callbacks.fireList(r.callbacks, options.context);
                }
            },
            error: function (xhr, textStatus, errorThrown) {
                Beers.pageLoader(false);

                new Beers.dialog({content: "Si è verificato un errore durante l'operazione. Riprova più tardi"});
            }
        };

        // CALLBACKS REWRITE
        $.each(callbacks, function (name) {
            if (options.hasOwnProperty(name)) {
                var real = options[name];
                var defa = callbacks[name];
                callbacks[name] = function (r) {
                    real(r);
                    defa(r);
                };
                delete options[name];
            }
        });

        // OPTIONS
        var options = $.extend(true, {
            context: Beers.context,
            type: 'POST',
            dataType: 'json',
            success: $.noop,
            error: $.noop,
            complete: $.noop
        }, options, callbacks);

        return $.ajax(options);
    };

    // DIALOG
    Beers.dialog = function (options) {
        var self = this;

        self.dialog = false;
        self.inner = false;
        self.content = false;
        self.options = $.extend({
            show: true,
            close: true,
            backclose: true,
            className: undefined,
            content: undefined,
            target: undefined,
            ajax: {
                type: 'html',
                url: undefined,
                post: {}
            },
            iframeVideo: undefined,
            iframe: undefined,
            buttons: [
                {
                    'label': 'Ok',
                    'action': 'close'
                }
            ],
            onOpen: $.noop,
            onClose: $.noop
        }, options);

        self.open = function () {
            _init(function () {
                var bw_before = $('body').width();
                Beers.documentLock(true);
                $('body').addClass('bee-dialog-open');
                var bw_after = $('body').width();
                if (bw_after > bw_before) {
                    $('body,[data-mrf]').css('margin-right', bw_after - bw_before);
                }
                setTimeout(function () {
                    self.dialog.addClass('bee-dialog-in');
                    if (self.options.className !== undefined) {
                        self.dialog.addClass(self.options.className);
                    }
                    self.dialog.trigger('beers:dialog.open');
                    Beers.load(self.dialog);
                    _triggerFunction('open', self.options.onOpen);
                    if(typeof window.EPP !== 'undefined') {
                        window.EPP.consent.load();
                    }
                }, 10);
            });
        };

        self.close = function () {
            self.dialog.removeClass('bee-dialog-in');
            self.dialog.one(Beers.css.event.transitionEnd, function () {
                Beers.documentLock(false);
                $('body').removeClass('bee-dialog-open');
                $('body,[data-mrf]').css('margin-right', '');
                self.dialog.trigger('beers:dialog.close');
                _triggerFunction('close', self.options.onClose);
                self.dialog.remove();
            });
        };

        function _init(ok) {
            _loadContent(function () {
                _create();
                ok();
            });
        }

        function _loadContent(loaded) {
            if (self.options.content !== undefined) {
                self.content = self.options.content;
                return loaded();
            }

            if (self.options.target !== undefined) {
                if ($(self.options.target).length) {
                    self.content = $(self.options.target).html();
                }
                return loaded();
            }

            if (typeof self.options.ajax === 'string') {
                self.options.ajax = {
                    type: 'html',
                    url: self.options.ajax,
                    post: {}
                };
            }

            if (self.options.ajax.url !== undefined) {
                Beers.ajax({
                    url: self.options.ajax.url,
                    data: self.options.ajax.post,
                    success: function (r) {
                        if (self.options.ajax.type === 'html') {
                            self.content = r;
                        } else if (self.options.ajax.type === 'json') {
                            if (r.s === true) {
                                self.content = r.c;
                            }
                        }
                        return loaded();
                    },
                    dataType: self.options.ajax.type
                });
                return;
            }

            if (self.options.iframeVideo !== undefined) {
                self.content = $('<div class="bee-video-iframe"><div class="bee-video-iframe-inner"><iframe src="' + self.options.iframeVideo + '" /></div></div>');
                return loaded();
            }

            if (self.options.iframe !== undefined) {
                self.content = $('<iframe />', {'src': self.options.iframe});
                return loaded();
            }
        }

        function _create() {
            self.dialog = $('<div />', {'class': 'bee-dialog'});
            self.inner = $('<div />', {'class': 'bee-dialog-inner'}).appendTo(self.dialog);

            // Main
            var main = $('<div />', {'class': 'bee-dialog-main', 'html': self.content}).appendTo(self.inner);

            // Foot
            if (self.options.buttons.length) {
                var foot = $('<div />', {'class': 'bee-dialog-foot'}).appendTo(self.inner);
                $.each(self.options.buttons, function (i, button) {
                    if(button.hasOwnProperty('href')){
                        var btn = $('<a />', {'href': button.href});
                    } else {
                        var btn = $('<button />', {'type': 'button'});

                        if (typeof button.action === 'string') {
                            btn.attr('data-dialog-action', button.action);
                        } else if (typeof button.action === 'function') {
                            btn.on('click', button.action);
                        }
                    }

                    btn.addClass(button.className || 'btn btn-primary').text(button.label);

                    if(typeof button.attr === 'object'){
                        $.each(button.attr, function(buttonAttrName, buttonAttrValue){
                            btn.attr(buttonAttrName, buttonAttrValue);
                        });
                    }

                    btn.appendTo(foot);
                });
            }

            // Close
            if (self.options.close === true) {
                self.dialog.addClass('bee-has-close');
                self.inner.append('<button class="bee-dialog-close" data-dialog-action="close" type="button"></button>');

                if (self.options.backclose === true) {
                    self.dialog.on('mousedown', function (e) {
                    if (!$(e.target).closest(self.inner).length) {
                            self.close();
                        }
                    });
                }
            }

            // Actions
            self.dialog.on('click', '[data-dialog-action]', function (e) {
                switch ($(this).data('dialog-action')) {
                    case 'close':
                        self.close();
                        break;
                }
            });

            self.dialog.data('bee-dialog', self);
            $('body').append(self.dialog);
        }

        function _triggerFunction(action, val) {
            if(typeof val === 'string' && typeof window[val] === 'function') {
                window[val].apply(self);
            } else if(typeof val === 'function'){
                val.apply(self);
            }
            $(window).trigger('bee:dialog.' + action, [self])
        }

        if (self.options.show === true) {
            self.open();
        }
    };

    Beers.dialogCloseAll = function () {
        $('.bee-dialog').each(function () {
            var dialog = $(this).data('bee-dialog') || false;
            if (dialog) {
                dialog.close();
            }
        });
    };

    // Img Load
    Beers.imgLoad = new function() {

        var workingMax = 3;
        var container = {};

        function flush() {
            $.each(container, function(priority, queue){
                if(queue.working > workingMax - 1){
                    return;
                }

                var item = queue.items.shift();
                if(item) {
                    queue.working++;
                    var img = new Image();
                    img.onload = function(){
                        if(typeof item[1] === 'function'){
                            item[1]();
                        }
                        queue.working--;
                        flush();
                    }
                    img.src = item[0]
                }
            })
        }

        return function(path, callback, priority){
            priority = priority || 100;
            if(typeof container[priority] === 'undefined'){
                container[priority] = {working: 0, items: []};
            }

            container[priority].items.push([path, callback]);

            flush();
        }
    }();

    // Document Lock
    var documentLockCount = 0;
    var documentLockfreezeVp = function(e) {
        e.preventDefault();
        e.stopPropagation();
    };
    Beers.documentLock = function (bool) {
        if (bool === true) {
            documentLockCount ++;
            if(!$('html').hasClass('bee-document-lock') && documentLockCount == 1){
                var ww = $(window).width();

                $(window).off("scroll touchmove", documentLockfreezeVp).on("scroll touchmove", documentLockfreezeVp);

                $('html').addClass('bee-document-lock');

                var mr = $(window).width() - ww;
                if(mr > 0){
                    $('html').css('margin-right', mr);
                    $('[data-bee-dlr]').css('right', mr);
                }
            }
        } 

        else if(bool === false) {
            documentLockCount--;
            if($('html').hasClass('bee-document-lock') && documentLockCount == 0){
                $(window).off("scroll touchmove", documentLockfreezeVp);

                $('html').removeClass('bee-document-lock bee-document-lock-sy').css('margin-right', 0);
                $('[data-bee-dlr]').css('right', 0);
            }
        } 

        return $('html').hasClass('bee-document-lock');
    };

    // Light Box
    Beers.lightBox = function (options) {
        var self = this;

        /* Options 
         ------------------------------ */
        var options = $.extend({
            show: true,
            index: 0,
            gallery: [],
            width: undefined,
            height: undefined,
            maxWidth: 1920,
            maxHeight: 1080,
            page: true,
            closeButton: true,
            thumbs: {
                width: 100,
                height: 75
            }
        }, options);

        /* Lightbox 
         ------------------------------ */
        var lb = {
            classes: {
                transitionIn: 'bee-lightbox-in',
                transitionShow: 'bee-lightbox-show',
                loading: 'bee-lightbox-loading',
                swipe: 'bee-lightbox-swipe'
            },
            tpl: '<div class="bee-lightbox"><div class="bee-lightbox-container"></div></div>',
            single: (options.gallery.length > 1) ? false : true,
            items: []
        };

        /* Tools 
         ------------------------------ */
        var tool = {
            getIndex: function (index) {
                if (index < 0) {
                    index = options.gallery.length - Math.abs(index % options.gallery.length);
                }
                if (index > options.gallery.length - 1) {
                    index = index % options.gallery.length;
                }

                return index;
            },
            getItem: function (index, complete) {
                self.lightbox.removeClass(lb.classes.loading);

                if (typeof lb.items[index] !== 'undefined') {
                    return complete(lb.items[index]);
                } else if (typeof options.gallery[index] !== 'undefined') {
                    var item = options.gallery[index];
                    var content;

                    switch (item.type || undefined) {
                        case 'iframe':
                            content = $('<iframe />', {
                                src: item.src
                            });
                            lb.items[index] = tool.createItem(content, item, index);
                            return complete(lb.items[index]);

                        case 'video-iframe':
                            content = $('<div class="bee-video-iframe"><div class="bee-video-iframe-inner"><iframe /></div></div>');
                            $('iframe', content).attr('src', item.src);
                            lb.items[index] = tool.createItem(content, item, index);
                            return complete(lb.items[index]);

                        default:
                            self.lightbox.addClass(lb.classes.loading);
                            Beers.imgLoad(item.src, function() {
                                self.lightbox.removeClass(lb.classes.loading);
                                content = $('<img />', {src: item.src});
                                lb.items[index] = tool.createItem(content, item, index);
                                return complete(lb.items[index]);
                            });
                            return;
                    }
                }

                return complete(-1);
            },
            createItem: function (content, item, index) {
                var itemInnerTpl = '<div class="bee-lightbox-item-inner"><div class="bee-lightbox-item-content"></div></div>';

                var inner = $(itemInnerTpl);
                
                // Content
                content.addClass('bee-lightbox-item-main');
                $('.bee-lightbox-item-content', inner).append(content);

                var bar = $('<div class="bee-lightbox-item-bar"></div>').appendTo(inner);
                
                // Caption
                if (typeof item.caption !== 'undefined') {
                    $('<div class="bee-lightbox-item-caption"></div>').html(item.caption).appendTo(bar);
                }

                // Page
                if(options.page !== false && options.gallery.length > 1){
                    $('<div class="bee-lightbox-item-page"></div>').text((index + 1) + ' / ' + options.gallery.length).appendTo(bar);
                }

                return inner;
            },
            refreshItem: function (item) {
                var inner = $('.bee-lightbox-item-inner', item);
                if (!inner.length) {
                    return;
                }

                var content = $('.bee-lightbox-item-content .bee-lightbox-item-main', inner);

                // Reset
                content.attr('style', '');

                // Content Dimensions
                if (options.width && options.height) {
                    content.width(options.width);
                    content.height(options.height);
                } else if (options.width) {
                    content.width(options.width);
                } else if (options.height) {
                    content.height(options.height);
                }
                var contentWidth = content.width();
                var contentHeight = content.height();
                var contentRatio = contentWidth / contentHeight;

                // Resize Dimensions
                var resizeWidth = Math.min(inner.width(), options.maxWidth, contentWidth);
                var resizeHeight = Math.min(inner.height(), options.maxHeight, contentHeight);
                var resizeRatio = resizeWidth / resizeHeight;

                // Resize
                if (contentRatio < resizeRatio) {
                    resizeWidth = resizeHeight * content.width() / content.height();
                }

                content.width(Math.round(resizeWidth));
                content.height(Math.round(resizeHeight));
            }
        };

        /* Functions 
         ------------------------------ */
        var fns = {
            refresh: function () {
                tool.refreshItem(self.currentItem);
                tool.refreshItem(self.prevItem);
                tool.refreshItem(self.nextItem);

                fns.extensions('refresh');
            },
            extensions: function (action) {
                $.each(extensions, function (i, extension) {
                    extension[action]();
                });
            }
        };

        /* Events 
         ------------------------------ */
        var events = {
            attach: function () {
                self.lightbox.on('click', '[data-lightbox-action]', events.fns.actions);
                self.lightbox.on('click', events.fns.outsideClose);
                $(window).on('keyup', events.fns.keyboard);
                events.fns.scrollLock.init();
                $(window).on('scroll touchmove', events.fns.scrollLock.evt);
                $(window).on('touchstart touchmove touchend', events.fns.touch.evt);
                $(window).on('resize', fns.refresh);
            },
            detach: function () {
                self.lightbox.off('click', '[data-lightbox-action]', events.fns.actions);
                self.lightbox.off('click', events.fns.outsideClose);
                $(window).off('keyup', events.fns.keyboard);
                events.fns.scrollLock.stop();
                $(window).off('scroll touchmove', events.fns.scrollLock.evt);
                $(window).off('touchstart touchmove touchend', events.fns.touch.evt);
                $(window).off('resize', fns.refresh);
            },
            fns: {
                actions: function (e) {
                    e.preventDefault();
                    e.stopPropagation();

                    switch ($(this).data('lightbox-action')) {
                        case 'prev':
                            self.prev();
                            break;
                        case 'next':
                            self.next();
                            break;
                        case 'close':
                            self.close();
                            break;
                    }
                },
                outsideClose: function (e) {
                    if (!options.closeButton && !$(e.target).closest('.bee-lightbox-item-inner').length) {
                        e.preventDefault();
                        self.close();
                    }
                },
                keyboard: function (e) {
                    e.preventDefault();
                    e.stopPropagation();

                    switch (e.which) {
                        case 37: // Left
                        case 38: // Top
                            self.prev();
                            break;
                        case 39: // Right
                        case 40: // Bottom
                            self.next();
                            break;
                        case 27: // Close
                            self.close();
                            break;
                    }
                },
                scrollLock: {
                    lock: false,
                    top: 0,
                    init: function () {
                        events.fns.scrollLock.lock = true;
                        events.fns.scrollLock.top = $(window).scrollTop();
                    },
                    stop: function () {
                        events.fns.scrollLock.lock = false;
                    },
                    evt: function (e) {
                        if (events.fns.scrollLock.lock === true) {
                            e.preventDefault();
                            $(window).scrollTop(events.fns.scrollLock.top);
                            return false;
                        }
                    }
                },
                touch: {
                    data: {
                        locked: false,
                        start: {x: 0, y: 0, time: 0}, // Start position / time
                        end: {x: 0, y: 0}, // End position / time
                        diff: {lock: false, x: 0, y: 0}
                    },
                    evt: function (e) {
                        var data = events.fns.touch.data;
                        var touch = e.originalEvent.targetTouches[0];

                        if (data.locked || $('body').hasClass('no-touch')) {
                            return;
                        }

                        switch (e.type) {

                            // Start
                            case 'touchstart':
                                data.start.x = touch.pageX;
                                data.start.y = touch.pageY;
                                data.start.time = new Date().getTime();

                                self.lightbox.addClass(lb.classes.swipe);
                                break;


                                // Move
                            case 'touchmove':

                                // Update End
                                data.end.x = touch.pageX;
                                data.end.y = touch.pageY;

                                // Update Data
                                var diff = {
                                    x: -(data.start.x - data.end.x),
                                    y: -(data.start.y - data.end.y)
                                };

                                data.diff.x = Math.abs(diff.x);
                                data.diff.y = Math.abs(diff.y);

                                if (lb.single) {
                                    data.diff.x = 0;
                                }

                                if (data.diff.lock !== 'y' && data.diff.x > data.diff.y) {
                                    data.diff.lock = 'x';
                                    data.diff.y = 0;
                                } else {
                                    data.diff.lock = 'y';
                                    data.diff.x = 0;
                                }

                                // Move X
                                if (data.diff.x > 3) {
                                    self.container.css('transform', 'translateX(' + diff.x.toString() + 'px)');
                                }

                                // Move Y
                                else if (data.diff.y > 3) {
                                    var rgba = Math.round(9 - data.diff.y * 9 / (self.container.height() / 2));
                                    self.lightbox.css('background-color', 'rgba(0,0,0,0.' + rgba + ')');
                                    self.container.css('transform', 'translateY(' + diff.y.toString() + 'px)');
                                }
                                break;


                                // End
                            case 'touchend':
                                self.lightbox.removeClass(lb.classes.swipe);

                                // End X
                                if (data.diff.lock === 'x') {
                                    data.locked = true;

                                    var diffXTime = new Date().getTime() - data.start.time;
                                    var diffX100 = data.diff.x * 100 / self.container.width();

                                    // Goto
                                    if ((40 < diffX100 && diffX100 <= 100) || (data.diff.x > 20 && diffXTime < 200)) {
                                        var moveX = (data.start.x < data.end.x) ? 'prev' : 'next';
                                        if (moveX === 'prev') {
                                            self.container.css('transform', 'translateX(100%)');
                                        } else {
                                            self.container.css('transform', 'translateX(-100%)');
                                        }

                                        self.lightbox.one(Beers.css.event.transitionEnd, function () {
                                            data.locked = false;
                                            self.lightbox.addClass(lb.classes.swipe);
                                            self.container.css('transform', 'translateX(0)');

                                            if (moveX === 'prev') {
                                                self.prev();
                                            } else {
                                                self.next();
                                            }
                                        });
                                    }

                                    // Replace
                                    else {
                                        data.locked = false;
                                        self.container.css('transform', 'translateX(0)');
                                    }
                                }

                                // End Y
                                else if (data.diff.lock === 'y') {
                                    data.locked = true;

                                    var diffYTime = new Date().getTime() - data.start.time;
                                    var diffY100 = data.diff.y * 100 / self.container.height();

                                    // Close
                                    if ((15 < diffY100 && diffY100 <= 100) || (data.diffy > 10 && diffYTime < 200)) {
                                        var moveY = (data.start.y < data.end.y) ? 'up' : 'down';

                                        if (moveY === 'up') {
                                            self.container.css('transform', 'translateY(100%)');
                                        } else {
                                            self.container.css('transform', 'translateY(-100%)');
                                        }
                                        self.lightbox.css('background-color', 'rgba(0,0,0,0)');

                                        self.lightbox.one(Beers.css.event.transitionEnd, function () {
                                            data.locked = false;
                                            self.close();
                                        });
                                    }

                                    // Replace
                                    else {
                                        self.lightbox.css('background-color', '');
                                        self.container.css('transform', 'translateY(0)');
                                        data.locked = false;
                                    }
                                }

                                // Reset   
                                data.start = {x: 0, y: 0, time: 0}; // Start position / time
                                data.end = {x: 0, y: 0}; // End position / time
                                data.diff = {lock: false, x: 0, y: 0};
                                break;
                        }
                    }
                }
            }
        };

        /* Extensions 
         ------------------------------ */
        var extensions = {
            thumbs: {
                ready: false,
                el: {
                    container: false,
                    inner: false
                },
                attach: function () {
                    if (lb.single || Beers.view.max('xs')) {
                        return;
                    }

                    var thumbs = this;

                    // Thumbs
                    thumbs.el.container = $('<div class="bee-lightbox-thumbs"></div>').appendTo(self.lightbox);
                    thumbs.el.inner = $('<div class="bee-lightbox-thumbs-inner"></div>').appendTo(thumbs.el.container);

                    var innerW = 0;

                    // Gallery
                    $.each(options.gallery, function (i, item) {
                        var thumb = $('<div class="bee-lightbox-thumb"></div>').appendTo(thumbs.el.inner);

                        // Style
                        thumb.css({
                            'width': options.thumbs.width,
                            'height': options.thumbs.height
                        });

                        Beers.imgLoad(item.src, function() {
                            thumb.css({
                                'background-image': 'url(' + item.src + ')'
                            });
                        }, 200);

                        // Events
                        thumb.on('click', function (e) {
                            e.stopPropagation();
                            self.goto(i);
                        });

                        // Render
                        innerW += thumb.outerWidth(true);
                    });

                    // Render
                    thumbs.el.inner.width(innerW);

                    // Lightbox
                    self.container.css('bottom', thumbs.el.inner.outerHeight(true));
                },
                refresh: function () {
                    var thumbs = this;

                    if (lb.single || Beers.view.max('xs')) {
                        return thumbs.detach();
                    }

                    if (!thumbs.el.container) {
                        thumbs.attach();
                    }
                    
                    var thumb = $('.bee-lightbox-thumb', thumbs.el.inner).eq(self.index);
                    $('.bee-lightbox-thumb', thumbs.el.inner).removeClass('active');
                    thumb.addClass('active');
                    var thumbW = (thumb.length) ? thumb.width() : 0;
                    var thumbX = (thumb.length) ? thumb.position().left : 0;

                    var translateX = (self.container.width() - thumbW) / 2 - thumbX;
                    thumbs.el.inner.css('transform', 'translateX(' + translateX + 'px)');

                    if (thumbs.ready === false) {
                        thumbs.ready = true;
                        setTimeout(function () {
                            thumbs.el.container.addClass('bee-lightbox-thumbs-ready');
                        }, 5);
                    }
                },
                detach: function () {
                    var thumbs = this;

                    if (!thumbs.el.container) {
                        return;
                    }

                    thumbs.el.container.remove();
                    thumbs.el.inner.remove();

                    thumbs.ready = false;
                    thumbs.el.container = false;
                    thumbs.el.inner = false;

                    // Lightbox
                    self.container.css('bottom', '');
                }
            }
        };

        /* Public 
         ------------------------------ */
        self.lightbox = $(lb.tpl);
        self.container = $('.bee-lightbox-container', self.lightbox);
        if(options.closeButton){
            var closeButton = '<button type="button" data-lightbox-action="close" class="bee-lightbox-item-control-close"><i class="fa-solid fa-xmark"></i></button>';
            self.lightbox.append(closeButton);
        }

        // Controls
        if (!lb.single) {
            var buttonsTpl = '<button type="button" data-lightbox-action="prev" class="bee-lightbox-item-control-prev"><i class="fa-solid fa-arrow-left"></i></button>' +
                '<button type="button" data-lightbox-action="next" class="bee-lightbox-item-control-next"><i class="fa-solid fa-arrow-right"></i></button>';
            self.lightbox.append(buttonsTpl);
        }

        self.currentItem = $('<div class="bee-lightbox-item bee-lightbox-item-current" />').appendTo(self.container);
        self.prevItem = $('<div class="bee-lightbox-item bee-lightbox-item-prev" />').appendTo(self.container);
        self.nextItem = $('<div class="bee-lightbox-item bee-lightbox-item-next" />').appendTo(self.container);

        self.index = false;
        

        self.open = function () {
            var bw_before = $('body').width();
            $('body').append(self.lightbox);
            Beers.documentLock(true);
            var bw_after = $('body').width();
            if (bw_after > bw_before) {
                $('body,[data-mrf]').css('margin-right', bw_after - bw_before);
            }
            setTimeout(function () {
                events.attach();
                fns.extensions('attach');
                self.lightbox.addClass(lb.classes.transitionIn);
                self.goto(options.index);
            }, 5);
        };

        self.goto = function (index) {
            index = (index && !lb.single) ? tool.getIndex(index) : 0;
            if (self.index === index) {
                return;
            }
            if (index < 0) {
                return self.close();
            }

            self.lightbox.addClass(lb.classes.loading);

            self.index = index;

            var prevIndex = tool.getIndex(self.index - 1);
            var nextIndex = tool.getIndex(self.index + 1);

            // Current
            tool.getItem(self.index, function (currentItem) {
                self.currentItem.html(currentItem.clone());
                self.currentItem.css('transform', 'translateX(0)');
                fns.refresh();
                
                self.lightbox.addClass(lb.classes.transitionShow);
            });

            if (!lb.single) {
                // Prev
                tool.getItem(prevIndex, function (prevItem) {
                    self.prevItem.html(prevItem.clone());
                    self.prevItem.css('transform', 'translateX(-100%)');
                    tool.refreshItem(self.prevItem);
                });

                // Next
                tool.getItem(nextIndex, function (nextItem) {
                    self.nextItem.html(nextItem.clone());
                    self.nextItem.css('transform', 'translateX(100%)');
                    tool.refreshItem(self.nextItem);
                });
            }
        };

        self.prev = function () {
            self.goto(self.index - 1);
        };

        self.next = function () {
            self.goto(self.index + 1);
        };

        self.close = function () {
            self.lightbox.removeClass(lb.classes.transitionShow);
            self.lightbox.removeClass(lb.classes.transitionIn);
            self.lightbox.one(Beers.css.event.transitionEnd, function () {
                self.index = 0;
                Beers.documentLock(false);
                $('body,[data-mrf]').css('margin-right', '');
                events.detach();
                fns.extensions('detach');
                self.lightbox.remove();
            });
        };

        if (options.show === true) {
            self.open();
        }
    };

    // Facebook Login
    Beers.facebookLogin = function(options) {
        if(options.logged && !options.loggedWithFacebook){
            return;
        }

        // options.appId
        // options.version
        // options.loginUrl
        // options.logoutUrl
        // options.loggedWithFacebook
        
        window.fbAsyncInit = function() {
            FB.init({
                appId            : options.appId,
                autoLogAppEvents : true,
                xfbml            : true,
                version          : options.version || 'v6.0'
            });

            var lastLoginAction = '';

            function Login(login) {
                FB.getLoginStatus(function(response) {
                    if(response.authResponse){   
                        LoginStore(response);
                    } else if(login){
                        FB.login(function(response) {
                            if(!response.authResponse){   
                                new Beers.dialog(window.site_language.MSG_AJAX_ERROR);
                            } else {
                                LoginStore(response);
                            }
                        }, {scope: 'public_profile,email'});
                    }
                });
            }

            function LoginStore(response) {
                if(response.authResponse){
                    FB.api('/me?fields=id,first_name,last_name,email', function(response) {
                        if(typeof options.onLogin === 'function'){
                            options.onLogin(response);
                        } else {
                            Beers.ajax({url: options.loginUrl, data: {d: response, action: lastLoginAction}});
                        }
                    });
                }
            }

            function Logout() {
                FB.getLoginStatus(function(response) {
                    if(response.authResponse){   
                        FB.logout();
                    }
                    LogoutStore();
                });
            }

            function LogoutStore(){
                Beers.ajax({url: options.logoutUrl});
            }

            $(document).on('click', '[data-facebook-login]', function(e) {
                lastLoginAction = $(this).attr('data-action') || '';
                e.preventDefault();
                Login(true);
            });
            $('[data-facebook-logout]').on('click', function() {
                Logout(true);
            });
        };
        
        $('body').append('<script async defer src="https://connect.facebook.net/en_US/sdk.js"></script><div id="fb-root"></div>');
    };

    // Google Login
    Beers.googleLogin = function(options) {
        if(options.logged){
            return;
        }

        // options.clientId
        // options.loginUrl

        window.attachGoogleLogin = function() {
            $('[data-google-login]').each(function() {
                var action = $(this).attr('data-action') || '';
                auth2.attachClickHandler(this, {},
                function(googleUser) {
                    var profile = googleUser.getBasicProfile();
                    var d = {
                        id: profile.getId(),
                        first_name: profile.getGivenName(),
                        last_name: profile.getFamilyName(),
                        email: profile.getEmail()
                    };
                    if(typeof options.onLogin === 'function'){
                        options.onLogin(d);
                    } else {
                        Beers.ajax({url: options.loginUrl, data: {d: d, action: action}});
                    }
                }, function(error) {
                    new Beers.dialog(window.site_language.MSG_AJAX_ERROR);
                });
            });
        };
        
        window.gapi_onload = function() {
            gapi.load('auth2', function(){
                auth2 = gapi.auth2.init({
                    client_id: options.clientId,
                    cookiepolicy: 'single_host_origin'
                });
                attachGoogleLogin();
            });
        };

        $('body').append('<script src="https://apis.google.com/js/api:client.js"></script>');
    };

    // FILTER ATTR
    Beers.filterAttr = function (element, prefix) {
        var self = this;

        if (!element.attributes) {
            return;
        }

        var obj = {};
        $.each(element.attributes, function () {
            var key;
            if (prefix && this.name.indexOf(prefix) === 0) {
                key = this.name.replace(prefix, "");
            } else if (!prefix) {
                key = this.name;
            }
            if (key) {
                key = self.trim(key, '-');
                self.set(obj, key, this.value, '-');
            }
        });
        return obj;
    };

    // SET
    Beers.set = function (obj, key, value, separator) {
        if (!key) {
            return value;
        }

        if (!separator) {
            separator = '.';
        }

        var keys = key.split(separator);
        while (keys.length > 1) {
            key = keys.shift();
            if (!obj.hasOwnProperty(key)) {
                obj[key] = {};
            }
            obj = obj[key];
        }
        obj[keys.shift()] = value;
        return obj;
    };

    // TRIM
    Beers.trim = function (string, charlist) {
        var pattern = (!charlist) ? new RegExp('^\\s+|\\s+$', 'g') : new RegExp('^[' + charlist + ']+|[' + charlist + ']+$', 'g');
        return string.replace(pattern, '');
    };



    /*
     ============================================================
     PLUGINS
     ============================================================
     */


    var Plugins = {};


    /* AJAX FORM
     * ------------------------------------------------------------ */
    Plugins.ajaxform = {
        autobuild: true,
        selector: 'form[data-ajaxform]',
        create: function (form) {
            var self = this;

            var submitting = false;
            var submittin_delay = 300;

            var options = {
                method: $(form).attr('method'),
                action: $(form).attr('data-action') || $(form).attr('action'),
                enctype: $(form).attr('enctype') || false,
                confirm: $(form).data('confirm') || false
            };


            var submit = function (e) {
                if ($(this).data('ajaxform-disable') === true) {
                    return;
                }

                e.preventDefault();
                if ($(this).data('ajaxform-lock') === true) {
                    if($(this).data('ajaxform-lock-message')){
                        new Beers.dialog({content: $(this).data('ajaxform-lock-message')});
                    }
                    return;
                }

                if (submitting) {
                    return;
                }
                submitting = true;

                var request = {
                    context: form,
                    type: options.method,
                    url: options.action,
                    success: function (r) {
                        $(form).trigger('beers:ajaxform.success', [r]);
                    },
                    complete: function () {
                        setTimeout(function () {
                            submitting = false;
                        }, submittin_delay);
                    }
                };

                if (options.enctype === 'multipart/form-data') {
                    request.data = new FormData(form);
                    request.enctype = self.enctype,
                    request.processData = false;
                    request.contentType = false;
                } else {
                    request.data = $(form).serialize();
                }

                Beers.ajax(request);
            };

            $(form).off('submit', submit);
            $(form).on('submit', submit);
        }
    };

    /* AJAX CALL
     * ------------------------------------------------------------ */
    Plugins.ajaxcall = {
        autobuild: true,
        selector: '[data-call]',
        create: function (context) {

            var action = $(context).data('call');
            var event = $(context).data('call-event') || 'click';
            var method = $(context).data('call-method') || 'POST';
            var confirm = $(context).data('confirm') || false;

            function request() {
                var data = Beers.filterAttr(context, 'data-post');
                if($(context).is('input[type=checkbox]')){
                    data.name = $(context).attr('name');
                    data.val = $(context).is(':checked') ? $(context).val() : '';
                } else if($(context).is(':input')){
                    data.name = $(context).attr('name');
                    data.val = $(context).val();
                
                }
                Beers.ajax({
                    url: action,
                    type: method,
                    data: data
                });
            }

            function handler(e) {
                e.preventDefault();

                if(confirm){
                    var confirmDialog = new Beers.dialog({
                        content: confirm,
                        buttons: [
                            {
                                'label': 'No',
                                'className': 'btn btn-light',
                                'action': 'close'
                            },
                            {
                                'label': 'Sì',
                                'className': 'btn btn-primary',
                                'action': function(){
                                    confirmDialog.close();
                                    request();
                                }
                            }
                        ]
                    });
                } else {
                    request();
                }
            }

            $(context).off(event, handler);
            $(context).on(event, handler);
        }
    };

    /* ANIMATE
     * ------------------------------------------------------------ */
    Plugins.animate = {
        autobuild: true,
        selector: '[data-ani]',
        create: function(context){
            var animate = true;
            var animationName = $(context).attr('data-ani');
            var delay = $(context).attr('data-ani-delay') || 30;
            var single = $(context).attr('data-ani-single') === 'true';

            $(context).addClass('bee-ani bee-' + animationName);

            $(window).on('scroll beers:animate.init', function() {
                if(Beers.view.isElementInView(context)){
                    if(animate){
                        setTimeout(function() {
                            $(context).addClass('bee-ani-in');
                            animate = false;
                        }, delay);
                    }
                } else {
                    if(single) return;
                    $(context).removeClass('bee-ani-in');
                    animate = true;
                }
            }).trigger('beers:animate.init');
        }
    };

    /* BOX
     * ------------------------------------------------------------ */
    Plugins.box = {
        autobuild: true,
        selector: '[data-box]',
        create: function (context) {
            $(context).on('click', function (e) {
                e.preventDefault();
                Plugins.box.load(this);
            });
        },

        load: function (obj) {
            var current = $(obj);

            var className = current.data('box-class') || '';
            if(current.data('box-size')) {
                className += ' bee-dialog-size-' + current.data('box-size');
            }

            var options = {
                className: className,
                target: current.data('box-target'),
                ajax: {
                    type: current.data('box-ajax-type') || 'html',
                    url: current.data('box-ajax'),
                    post: Beers.filterAttr(obj, 'data-box-post')
                },
                iframeVideo: current.data('box-iframe-video'),
                iframe: current.data('box-iframe'),
                buttons: []
            };

            if(current.data('box-onopen')){
                options.onOpen = current.data('box-onopen');
            }

            new Beers.dialog(options);
        }
    };

    /* CAROUSEL
     * ------------------------------------------------------------ */
    Plugins.carousel = {
        autobuild: function () {
            return ($.fn.slick !== undefined);
        },
        selector: '[data-carousel]',
        create: function (context) {
            var carousel = $(context);

            var current = carousel.children().index(carousel.children('.slick-current'));
            var options = $.extend({
                accessibility: false,
                arrows: false,
                dots: false,
                infinite: true,
                speed: 600,
                slidesToShow: 1,
                initialSlide: (current > 0) ? current : 0,
                prevArrow: '<button type="button" data-role="none" class="slick-prev fal fa-chevron-left" aria-label="Previous" tabindex="0" role="button"></button>',
                nextArrow: '<button type="button" data-role="none" class="slick-next fal fa-chevron-right" aria-label="Next" tabindex="0" role="button"></button>',
                customPaging: function (slider, i) {
                    return '<span></span>';
                }
            }, carousel.data('carousel') || {});
            var slick = carousel.slick(options);

            if(options.hasOwnProperty('navFrom')){
                slick.on('beforeChange', function(event, slick, currentSlide, nextSlide){
                    $(options.navFrom).slick('slickGoTo', nextSlide);
                    $('.slick-slide', options.navFrom).removeClass('slick-current');
                    $('.slick-slide[data-slick-index="' + nextSlide + '"]', options.navFrom).addClass('slick-current');
                });
            }
        }
    };

    /* GMAP
     * ------------------------------------------------------------ */
    Plugins.gmap = {
        autobuild: function () {
            if (typeof window.google === 'undefined') {
                return false;
            }
            return true;
        },
        selector: '[data-gmap]',
        create: function (context) {
            var self = this;

            var getOptions = function (options) {

                // PRESET
                options.lat = parseFloat(options.lat);
                options.lng = parseFloat(options.lng);


                // OPTIONS
                options = $.extend(true, {
                    lat: 0,
                    lng: 0,
                    content: '',
                    contentShow: false,
                    showMarker: false,
                    map: {
                        zoom: options.zoom || 11,
                        center: (options.lat && options.lng) ? {
                            lat: options.lat,
                            lng: options.lng
                        } : undefined,
                        mapTypeId: window.google.maps.MapTypeId.SATELLITE,
                        mapTypeControl: false,
                        streetViewControl: false,
                        fullscreenControl: false,
                        scrollwheel: false,
                        draggable: true,
                        // styles: [{"featureType": "administrative","elementType": "labels.text.fill","stylers": [{"color": "#444444"}]},{"featureType": "landscape","elementType": "all","stylers": [{"color": "#f2f2f2"}]},{"featureType": "poi","elementType": "all","stylers": [{"visibility": "off"}]},{"featureType": "road","elementType": "all","stylers": [{"saturation": -100},{"lightness": 45}]},{"featureType": "road.highway","elementType": "all","stylers": [{"visibility": "simplified"}]},{"featureType": "road.arterial","elementType": "labels.icon","stylers": [{"visibility": "off"}]},{"featureType": "transit","elementType": "all","stylers": [{"visibility": "off"}]},{"featureType": "water","elementType": "all","stylers": [{"color": "#46bcec"},{"visibility": "on"}]}]
                        styles: [
                            {
                                "featureType": "poi",
                                "elementType": "all",
                                "stylers": [
                                    {
                                        "visibility": "off"
                                    }
                                ]
                            },
                            {
                                "featureType": "road",
                                "elementType": "all",
                                "stylers": [
                                    {
                                        "visibility": "on"
                                    }
                                ]
                            },
                            {
                                "featureType": "road.highway",
                                "elementType": "all",
                                "stylers": [
                                    {
                                        "lightness": "70"
                                    },
                                    {
                                        "saturation": "-100"
                                    }
                                ]
                            },
                            {
                                "featureType": "road.highway",
                                "elementType": "labels.icon",
                                "stylers": [
                                    {
                                        "visibility": "off"
                                    }
                                ]
                            },
                            {
                                "featureType": "road.arterial",
                                "elementType": "labels.icon",
                                "stylers": [
                                    {
                                        "visibility": "off"
                                    }
                                ]
                            },
                            {
                                "featureType": "transit",
                                "elementType": "all",
                                "stylers": [
                                    {
                                        "visibility": "off"
                                    }
                                ]
                            }
                        ]
                    },
                    marker: {
                        icon: false,
                        size: false,
                        scaledSize: [30, 45],
                        anchor: [10, 30],
                        origin: [0, 0]
                    },
                    markers: []
                }, options || {});

                return options;
            };

            self.element = context;
            self.options = getOptions($(self.element).data('gmap'));
            self.map = false;
            self.markers = [];
            self.infowindow = new window.google.maps.InfoWindow();

            /* Constructor
             ------------------------------------------------------------*/
            self.init = function () {

                // Set map
                self.map = new window.google.maps.Map(self.element, self.options.map);

                // Fit bound min zoom
                window.google.maps.event.addListenerOnce(self.map, 'idle', function () {
                    self.map.setZoom(Math.min(self.options.map.zoom, self.map.getZoom()));
                });

                // Add markers
                if (self.options.markers.length) {
                    for (var i in self.options.markers) {
                        self.addMarker(self.options.markers[i]);
                    }
                    self.fitBounds();
                } else if (self.options.showMarker) {
                    self.addMarker();
                }
            };


            /* addMarker
             ------------------------------------------------------------*/
            self.addMarker = function (options) {
                options = $.extend({
                    position: false,
                    lat: self.options.lat,
                    lng: self.options.lng,
                    content: self.options.content,
                    contentShow: self.options.contentShow,

                    icon: self.options.marker.icon,
                    size: self.options.marker.size,
                    scaledSize: self.options.marker.scaledSize,
                    anchor: self.options.marker.anchor,
                    origin: self.options.marker.origin,
                    
                    draggable: false,
                    animation: undefined,
                    zIndex: undefined
                }, options || {});

                if (!options.position) {
                    options.lat = parseFloat(options.lat);
                    options.lng = parseFloat(options.lng);
                    options.position = {lat: options.lat, lng: options.lng};
                }

                // Marker Data
                var markerData = {
                    _options: options,
                    position: options.position,
                    map: self.map,
                    draggable: options.draggable,
                    animation: options.animation,
                    zIndex: options.zIndex
                };

                // Icon
                if (options.icon) {
                    markerData.icon = {
                        url: options.icon
                    };
                    
                    if(options.size){
                        markerData.icon.size = new window.google.maps.Size(options.size[0], options.size[1]);
                    }
                    if(options.scaledSize){
                        markerData.icon.scaledSize = new window.google.maps.Size(options.scaledSize[0], options.scaledSize[1]);
                    }
                    if(options.anchor){
                        markerData.icon.anchor = new window.google.maps.Point(options.anchor[0], options.anchor[1]);
                    }
                    if(options.origin){
                        markerData.icon.origin = new window.google.maps.Point(options.origin[0], options.origin[1]);
                    }
                }

                // Marker
                var marker = new window.google.maps.Marker(markerData);

                // Infowindow
                if (options.content) {
                    window.google.maps.event.addListener(marker, 'click', function () {
                        self.infowindow.setContent(options.content);
                        self.infowindow.open(self.map, marker);
                        Beers.load();
                    });

                    if (options.contentShow === true) {
                        window.google.maps.event.addListenerOnce(self.map, 'tilesloaded', function () {
                            self.infowindow.setContent(options.content);
                            self.infowindow.open(self.map, marker);
                        });
                    }
                }

                // Store
                self.markers.push(marker);
                return marker;
            };


            /* clearMarkers
             ------------------------------------------------------------*/
            self.clearMarkers = function () {
                for (var i in self.markers) {
                    self.markers[i].setMap(null);
                }
            };


            /* fitBounds
             ------------------------------------------------------------*/
            self.fitBounds = function () {
                var bounds = new window.google.maps.LatLngBounds();
                for (var i in self.markers) {
                    var marker = self.markers[i];
                    if (marker.getMap() === self.map) {
                        bounds.extend(marker.getPosition());
                    }
                }
                self.map.fitBounds(bounds);
                self.map.setZoom(Math.min(self.options.map.zoom, self.map.getZoom()));
            };


            /* Init
             ------------------------------------------------------------*/
            self.init();
        }
    };

    /* GALLERY
     * ------------------------------------------------------------ */
    Plugins.gallery = {
        autobuild: true,
        selector: '[data-gallery]',
        create: function (context) {
            $(context).on('click', function (e) {
                e.preventDefault();
                e.stopPropagation();
                Plugins.gallery.load(this);
            });
        },

        getItemData: function (obj) {
            var current = $(obj);

            return {
                src: current.data('gallery-href') || current.attr('href') || current.attr('src'),
                type: current.data('gallery-type') || false,
                caption: current.data('gallery-title') || current.attr('title') || current.attr('alt')
            };
        },

        load: function (obj) {
            var self = this;
            var current = $(obj);
            var group = false;

            if (current.data('gallery-open') || false !== false) {
                var openRef = current.data('gallery-open');
                current = $('[data-gallery][href="' + openRef + '"]');
                if(!current.length){
                    current = $('[data-gallery-group="' + openRef + '"] [data-gallery]').first();
                }
            }

            if (current.data('gallery-rel')) {
                group = $('[data-gallery][data-gallery-rel="' + current.data('gallery-rel') + '"]');
            } else if (current.attr('rel')) {
                group = $('[data-gallery][rel="' + current.attr('rel') + '"]');
            } else if (current.closest('[data-gallery-group]').length) {
                group = current.closest('[data-gallery-group]').find('[data-gallery]');
            } else {
                group = current;
            }

            if (!group) {
                return false;
            }

            var options = {
                index: group.index(current),
                width: current.data('gallery-width'),
                gallery: []
            };

            group.each(function () {
                options.gallery.push(self.getItemData(this));
            });

            new Beers.lightBox(options);
        }
    };


    /* LAZYLOAD
     * ------------------------------------------------------------ */
    Plugins.lazyload = {
        initialized: false,
        init: function (context) {
            if(!$('[data-laz]').length){
                return;
            }

            if(!Plugins.lazyload.initialized){
                var isWebp = $('html').hasClass('is-webp');
                $(window).on('scroll bee:lazyload.refresh', function() {
                    $('[data-laz]').each(function() {
                        var item = $(this);
                        
                        if(!Beers.view.isElementInView(item)) {
                            return;
                        }
                         
                        var src = (isWebp && item.attr('data-laz-webp')) ? item.attr('data-laz-webp') : item.attr('data-laz');
                        item.removeAttr('data-laz data-laz-webp');
                        Beers.imgLoad(src, function(){
                            if(item.is('img')){
                                item.attr('src', src);
                            } else {
                                item.css('background-image', 'url(' + src + ')');
                            }
                            // delete item;
                        });
                    });
                });
            }
            Plugins.lazyload.initialized = true;

            $(window).trigger('bee:lazyload.refresh');
        }
    };

    /* MAXLENGTH
     * ------------------------------------------------------------ */
    Plugins.maxlength = {
        autobuild: true,
        selector: '[data-maxlength]',
        create: function (context) {
            var textarea = $(context);
            var maxlength = textarea.attr('maxlength');
            var indicator = $('<span class="bee-maxlength-indicator"></span>');

            textarea.after(indicator);

            textarea.keyup(function(){
                indicator.text($(this).val().length + '/' + maxlength);
            });

        }
    };

    /* OFFCANVAS
     * ------------------------------------------------------------ */
    Plugins.offcanvas = {
        init: function (context) {

            // Classes
            var classes = {
                container: 'bee-offcanvas-container',
                offcanvas: 'bee-offcanvas',
                bar: 'bee-offcanvas-bar',
                barRtl: 'bee-offcanvas-bar-rtl',
                active: 'bee-offcanvas-active',
                open: 'bee-offcanvas-open'
            };

            // Options
            var o = {
                opening: false,
                open: false,
                barCurrent: false,
                barRtl: false,
                barMargin: false,
                lastDocumentLock: false
            };

            // Elements
            var $body = $('body');
            var $offcanvas = $('.' + classes.offcanvas);

            // Functions
            var fns = {
                open: function ($bar) {
                    // Status // Bar
                    if (o.opening === true || !$bar.length) {
                        return;
                    }
                    
                    // Update
                    o.opening = true;
                    o.barCurrent = $bar;
                    o.barRtl = (o.barCurrent.hasClass(classes.barRtl)) ? true : false;
                    o.barMargin = (o.barRtl) ? 'margin-right' : 'margin-left';

                    // Opening
                    o.lastDocumentLock = Beers.documentLock();
                    Beers.documentLock(true);
                    $offcanvas.css('display', 'block');
                    $body.addClass(classes.container);
                    o.barCurrent.css('display', 'block').addClass(classes.active);

                    // Bar
                    o.barCurrent.scrollTop(0);
                    o.barCurrent.css(o.barMargin, -o.barCurrent.width());

                    // Events
                    $(window).trigger('beers:offcanvas.opening');
                    o.barCurrent.trigger('beers:offcanvas.opening');

                    // Animation
                    var opts = {};
                    opts[o.barMargin] = 0;
                    o.barCurrent.animate(opts, {duration: 250, queue: false, complete: function () {
                        o.open = true;
                        o.barCurrent.addClass(classes.open);

                        // Events
                        $(window).trigger('beers:offcanvas.open');
                        o.barCurrent.trigger('beers:offcanvas.open');
                    }});

                    // State
                    Beers.history.push('#menu', {beersOffcanvasState: true});
                },
                close: function () {
                    if (Beers.history.state.is('beersOffcanvasState')) {
                        window.history.back();
                        return;
                    }

                    // Status
                    if (o.open === false) {
                        return;
                    }

                    // Animation
                    var opts = {};
                    opts[o.barMargin] = -o.barCurrent.width();
                    o.barCurrent.animate(opts, {duration: 250, queue: false, complete: function () {
                        o.barCurrent.css('display', 'none');
                        o.barCurrent.removeClass(classes.active).removeClass(classes.open);

                        o.open = false;

                        $offcanvas.css('display', 'none');
                        $body.removeClass(classes.container);
                        Beers.documentLock(o.lastDocumentLock);

                        // Events
                        $(window).trigger('beers:offcanvas.closed');
                        o.barCurrent.trigger('beers:offcanvas.closed');

                        // Update
                        o.opening = false;
                        o.barCurrent = false;
                        o.barRtl = false;
                        o.barMargin = false;
                        o.lastDocumentLock = false;

                        fns.touch.data = {
                            start: {x: 0, time: 0}, // Start position / time
                            end: {x: 0}, // End position / time
                            diffX: 0 // Diff X
                        };
                    }});
                },
                triggerOpen: function (e) {
                    e.preventDefault();
                    var barName = $(this).data('offcanvas');
                    var $bar = $('[data-offcanvas-bar="' + barName + '"]');
                    fns.open($bar);
                },
                touch: {
                    data: {
                        start: {x: 0, time: 0}, // Start position / time
                        end: {x: 0}, // End position / time
                        diffX: 0 // Diff X
                    },
                    evt: function (e) {
                        if (!o.opening || e.isDefaultPrevented() || o.barCurrent.attr('data-offcanvas-touch') == 'no') {
                            return;
                        }

                        // Elements
                        var $bar = o.barCurrent;
                        var data = fns.touch.data;
                        var touch = e.originalEvent.targetTouches[0];

                        switch (e.type) {

                            // Start
                            case 'touchstart':
                                data.start.x = touch.pageX;
                                data.start.time = new Date().getTime();
                                break;


                                // Move
                            case 'touchmove':
                                // Update End
                                data.end.x = touch.pageX;

                                // Update Data
                                data.diffX = (o.barRtl) ? data.end.x - data.start.x : data.start.x - data.end.x;

                                // Move
                                if (20 < data.diffX && data.diffX < $bar.width()) {
                                    $bar.css(o.barMargin, -data.diffX);
                                }
                                break;


                                // End
                            case 'touchend':
                                // Diff X
                                var diffTime = new Date().getTime() - data.start.time;
                                var diffX100 = data.diffX * 100 / $bar.width();

                                // Close
                                if ((40 < diffX100 && diffX100 <= 100) || (data.diffX > 30 && diffTime < 200)) {
                                    fns.close();
                                }

                                // Reopen
                                else {
                                    var opts = {};
                                    opts[o.barMargin] = 0;
                                    $bar.animate(opts, {duration: 50, queue: false});
                                }
                                break;
                        }
                    }
                }
            };

            $(context).off('touchstart touchmove touchend', fns.touch.evt);
            $(context).on('touchstart touchmove touchend', fns.touch.evt);

            $(context).off('click', '[data-offcanvas]', fns.triggerOpen);
            $(context).on('click', '[data-offcanvas]', fns.triggerOpen);

            $(context).on('click', '[data-offcanvas-close]', function () {
                fns.close();
            });
            $(window).on('beers:view.change', function () {
                fns.close();
            });

            $(window).on('click beers:offcanvas.close beers:history.pop', function (e) {
                var autoclose = e.type == 'click' && o.barCurrent ? o.barCurrent.attr('data-offcanvas-autoclose') || true : true;
                if (autoclose !== true || e.isDefaultPrevented() || !o.open || !o.barCurrent || (e.type === 'click' && o.barCurrent.has(e.target).length)) {
                    return;
                }

                // Se eseguo un History.back() o clicco al di fuori della barra chiudo quest'ultima
                e.preventDefault();
                fns.close();
            });
        }
    };

    /* POPUP
     * ------------------------------------------------------------ */
    Plugins.popup = {
        autobuild: false,
        selector: '[data-popup]',
        init: function (context) {
            function new_window(e) {
                e.preventDefault();

                var width = $(this).data('popup-w') || 800;
                var height = $(this).data('popup-h') || 600;
                var left = (screen.width - width) / 2;
                var top = (screen.height - height) / 2;
                var title = $(this).attr('title') || $(this).text();
                var url = $(this).attr('href');
                window.open(url, title, 'scrollbars=no,resizable=yes, width=' + width + ',height=' + height + ',left=' + left + ',top=' + top + ',status=no,location=no,toolbar=no');
            }

            $(window.document).off('click', '[data-popup]', new_window);
            $(window.document).on('click', '[data-popup]', new_window);
        }
    };

    /* Quantity Widget
     * ------------------------------------------------------------ */
    Plugins.qtyInput = {
        autobuild: true,
        selector: '[data-qty-input]',
        create: function (context) {
            var input = $('input', context);
            var value = $('[data-value]', context);
            var min = input.attr('min') ? parseInt(input.attr('min')) : 1;
            var max = input.attr('max') ? parseInt(input.attr('max')) : false;
            var inc = input.attr('data-inc') ? parseInt(input.attr('data-inc')) : 1;
            var val = input.val() ? parseInt(input.val()) : min;
            if(!val){
                val = 0;
            }
            var timeout;

            $('button', context).on('click', function () {
                clearTimeout(timeout);

                if ($(this).attr('data-action') == 'sub') {
                    val -= inc;
                    if (val <= min) {
                        val = min;
                    }
                } else if ($(this).attr('data-action') == 'add') {
                    val += inc;
                    if (max !== false && val >= max) {
                        val = max;
                    }
                }
                input.val(val);
                value.text(val);

                timeout = setTimeout(function() {
                    input.change();
                }, 200);
            });
        }
    };


    /* READMORE
     * ------------------------------------------------------------ */
    Plugins.readmore = {
        autobuild: true,
        selector: '[data-readmore]',
        create: function (context) {
            var initialized = false;
    
            context = $(context);
            var initialHeight = context.data('readmore') || 100;
            var contentHeight = context.height();
            var leggiMeno = context.attr('data-readmore-less');
            var leggiTutto = context.attr('data-readmore-more');
    
            if (contentHeight < initialHeight) {
                return;
            }

            var content = $('<div />', {'class': 'bee-readmore-content bee-readmore-closed'}).height(initialHeight);
            var control = $('<span />', {'class': 'bee-readmore-control', html: leggiTutto});

            control.on('click', function () {
                var content = $('.bee-readmore-content', context);
                if (content.hasClass('bee-readmore-closed')) {
                    control.text(leggiMeno);
                    content.removeClass('bee-readmore-closed').animate({height: contentHeight}, function () {
                        $(this).height('');
                    });
                } else {
                    control.text(leggiTutto);
                    content.animate({height: initialHeight}, function () {
                        $(this).addClass('bee-readmore-closed');
                    });
                }
            });

            context.addClass('bee-readmore').wrapInner(content).append(control);    
        }
    };

    /* Same Height
     * ------------------------------------------------------------ */
    Plugins.sameHeight = {
        autobuild: true,
        selector: '[data-same-height]',
        create: function (context) {
            var minView = $(context).attr('data-same-height') || 'xs';

            Plugins.sameHeight.apply(context, minView);
            
            $(window).on('beers:view.change', function() {
                Plugins.sameHeight.apply(context, minView);
            });
        },

        apply: function(context, minView) {
            if(Beers.view.min(minView)){      
                var vm = 0;
                $('[data-same-height-item]', context).each(function() {
                    if($(this).outerHeight() > vm){
                        vm = $(this).outerHeight();
                    }
                });
                
                $('[data-same-height-item]', context).css('min-height', vm);
            } else {
                $('[data-same-height-item]', context).css('min-height', '');
            }
        }
    };

    /* SCROLL
     * ------------------------------------------------------------ */
    Plugins.scroll = {
        autobuild: true,
        selector: '[data-scroll]',
        create: function (context) {
            var scroller = $(context);
            var scrollContext = window.document;
            var scroll = (scroller.data('scroll') || scroller.attr('href')).split('::');
            var target = scroll[0];
            var targetAction = scroll[1];
            var mt = scroller.data('scroll-mt') || parseInt($('#wrapper').css('padding-top')) || 100;

            function doScroll() {
                if(targetAction == 'next'){
                    target = $(scroll[0]).next();
                }

                var top = false;

                switch (target) {
                    case 'top'  :
                        top = 0;
                        break;
                    default     :
                        top = ($(target, scrollContext).length) ? $(target, scrollContext).offset().top : false;
                        break;
                }
                if (top !== false) {
                    if(scrollContext == window.document){
                        scrollContext = 'html,body';
                    }
                    $(scrollContext).animate({scrollTop: top - mt}, 800);
                }
            }

            scroller.on('click', function(e) {
                e.preventDefault();
                if($(e.target).closest('[data-offcanvas-bar]').length){
                    $(window).one('beers:offcanvas.closed', function() {       
                        doScroll();
                    }).trigger('beers:offcanvas.close');
                } else {
                    doScroll();
                }
            });

            if (target === 'top') {
                $(window).on('scroll bee:scroll.top.refresh', function (e) {
                    if (e.isDefaultPrevented()) {
                        return;
                    }
                    var show = ($(this).scrollTop() > 800) ? true : false;
                    scroller.toggleClass('in', show);
                }).trigger('bee:scroll.top.refresh');
            }

            $(window).on('scroll bee:scroll.top.refresh', function (e) {
                var window_bottom = $(window).scrollTop() + $(window).height() / 2;

                if ($(target).length) {
                    var target_top = $(target).offset().top;
                    var target_bottom = target_top + $(target).outerHeight(true);

                    if (window_bottom > target_top && window_bottom < target_bottom) {
                        $('[data-scroll]').removeClass('active');
                        scroller.addClass('active');
                    }
                }
            }).trigger('bee:scroll.top.refresh');
        }
    };

    /* SCROLLED
     * ------------------------------------------------------------ */
    Plugins.scrolled = {
        autobuild: true,
        selector: '[data-scrolled]',
        create: function (context) {
            var scrollContainer = $(context).attr('data-scrolled') || window;
            var from = $(context).attr('data-scrolled-from') || 0;
            $(scrollContainer).on('scroll bee:scrolled.refresh', function (e) {
                if (e.isDefaultPrevented() || Beers.documentLock()) {
                    return;
                }
                var show = ($(scrollContainer).scrollTop() > from) ? true : false;
                $(context).toggleClass('bee-scrolled', show);
            }).trigger('bee:scrolled.refresh');
        }
    };

    /* Ui Select
     * ------------------------------------------------------------ */
    Plugins.uiselect = {
        autobuild: function () {
            return ($.fn.select2 !== undefined);
        },
        selector: '[data-uiselect]',
        create: function (context) {
            var select = $(context);

            var options = $.extend({
                theme: "bootstrap-5"
            }, select.data('uiselect') || {});

            // Ajax 
            if(typeof options.ajax !== 'undefined'){
                options.ajax.delay = 250;
                options.ajax.processResults = function (data) {
                    var r = this.container.results;
                    if(data.message){
                        setTimeout(function() {
                                
                            r.clear();
                            r.hideLoading();
                            var $message = $('<li role="alert" aria-live="assertive"' +' class="select2-results__option select2-results__message">' + data.message + '</li>');
                            r.$results.append($message);
                        }, 50);
                        return false;
                    }
                    return data;
                };
            }

            // Parent Filter
            if(options.data || options.parent){
                options.ajax.data = function (params) {
                    if(options.data){
                        $.each(options.data, function(name, val) {
                            params[name] = val;
                        });
                    }
                    if(options.parent){
                        $.each(options.parent, function(i, name) {
                            params[name] = $('[name="' + name + '"]').val();
                        });
                    }
                    return $.param(params);
                };
            }

            // Dom
            select.select2(options);

            // Min max - Connected
            var minId = select.attr('data-uiselect-min');
            if(minId){
                var minTarget = $('[data-uiselect-max="' + minId + '"]');
                if(minTarget.length){
                    select.on('change', function() {
                        var value = $('option:selected', select).attr('data-uiselect-minmax-val') || this.value;
                        $('option', minTarget).each(function() {
                            var optionValue = $(this).attr('data-uiselect-minmax-val') || this.value;
                            if(parseInt(optionValue) < parseInt(value)){
                                $(this).attr('disabled', 'disabled').prop('disabled', true);
                            } else {
                                $(this).removeAttr('disabled').prop('disabled', false);
                            }
                        });
                    });
                }
            }
            var maxId = select.attr('data-uiselect-max');
            if(maxId){
                var maxTarget = $('[data-uiselect-min="' + maxId + '"]');
                if(maxTarget.length) {
                    select.on('change', function() {
                        var value = $('option:selected', select).attr('data-uiselect-minmax-val') || this.value;
                        $('option', maxTarget).each(function() {
                            var optionValue = $(this).attr('data-uiselect-minmax-val') || this.value;
                            if(parseInt(optionValue) > parseInt(value)){
                                $(this).attr('disabled', 'disabled').prop('disabled', true);
                            } else {
                                $(this).removeAttr('disabled').prop('disabled', false);
                            }
                        });
                    });
                }
            }
        }
    };


    
    /*
     ============================================================
     PUBLIC
     ============================================================
     */


    window.Beers = Beers;
    Beers.init();

    return window.Beers;

})(window, jQuery);