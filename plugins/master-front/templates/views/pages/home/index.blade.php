@extends('layouts.main')

{{-- Page-only CSS/JS: @push('styles') / @push('scripts') with a file in assets/main/, never inline --}}

@section('content')
  <section class="container">
    <h1>{{ Websites::current('description') }}</h1>
  </section>
@endsection
