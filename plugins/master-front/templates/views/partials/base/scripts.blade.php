<script>
  window.front = {
    route: '{{ Front::currentRouteName() }}',
    base_url: '{{ Websites::current("domain") }}',
    lang: '{{ App::getLocale() }}',
    google_api_key: '{{ Websites::current("google_api_key") }}',
    id_country_italia: "{{config('constants.front.id_country_italia')}}",
  }

  @if(Cache::store(config('master.translations.cache_driver'))->has('translations_front_' . App::getLocale()))
    window.front.translations = {!! Cache::store(config('master.translations.cache_driver'))->get('translations_front_' . App::getLocale()) ?? "''" !!};
    window.front.admin_translations = {!! Cache::store(config('master.translations.cache_driver'))->get('translations_admin_' . App::getLocale()) ?? "''" !!};
  @endif
</script>

<!-- Core -->
<script src="//cdn.ene.si/jquery/3.7.0/jquery.min.js"></script>

<!-- Lib -->

<!-- Theme -->
@if(config('app.debug'))
  <script src="{{ \Master\Facades\Version::get('/assets/common/beers/beers.js') }}"></script>
  <script src="{{ \Master\Facades\Version::get('/assets/main/js/main.js') }}"></script>
@else
  <script src="{{ \Master\Facades\Version::get('/assets/main/js/base.min.js') }}"></script>
@endif

@if(session()->has('callbacks'))
  <script>
    $(function(){
      if (window.front.callbacks && window.front.callbacks.length) {
        Beers.callbacks.fireList(window.front.callbacks);
      }
    });
  </script>
@endif
