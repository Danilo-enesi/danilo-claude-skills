<picture>
    @foreach($sources as $source)
        @if($loop->last && $srcsetWebp)
            <source type="image/webp" srcset="{{ $srcsetWebp }}" @if($sizes) sizes="{{ $sizes }}" @endif>
        @elseif($source['webp'])
            <source type="image/webp" srcset="{{ $source['webp'] }}" @if($source['media']) media="{{ $source['media'] }}" @endif>
        @endif
        @if($source['media'])
            <source srcset="{{ $source['url'] }}" media="{{ $source['media'] }}">
        @endif
    @endforeach
    <img src="{{ last($sources)['url'] }}" alt="{{ $alt }}"
         @if($srcsetUrl) srcset="{{ $srcsetUrl }}" @if($sizes) sizes="{{ $sizes }}" @endif @endif
         {{ $attributes->merge($priority ? ['loading' => 'eager', 'fetchpriority' => 'high', 'decoding' => 'async'] : ['loading' => 'lazy', 'decoding' => 'async']) }}>
</picture>
