@extends('layouts.main')

{{-- Error page, rendered by the core exception Handler (view `pages.errors`) with only $exception (getStatusCode(),
     getMessage(), getHeaders()) and an empty $errors. One page for every code: the title comes from
     front::errors.title_<code> when that key exists, otherwise the generic title + message. Extra data or meta: a view
     composer on 'pages.errors' (skill front-error-pages). --}}
@section('content')
  <section class="container py-5 text-center">
    <h1>@lang(Lang::has('front::errors.title_' . $exception->getStatusCode()) ? 'front::errors.title_' . $exception->getStatusCode() : 'front::errors.generic_title')</h1>
    @unless(Lang::has('front::errors.title_' . $exception->getStatusCode()))
      <p>@lang('front::errors.generic_message')</p>
    @endunless
    <p class="text-muted">@lang('front::errors.code', ['code' => $exception->getStatusCode()])</p>
    <a class="btn btn-primary" href="{{ Front::route('home') }}">@lang('front::errors.back_home')</a>
  </section>
@endsection
