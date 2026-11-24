<picture>
    @foreach($sources as $source)
        @if($source['webp'])
            <source type="image/webp" srcset="{{ $source['webp'] }}" @if($source['media']) media="{{ $source['media'] }}" @endif>
        @endif
        @if($source['media'])
            <source srcset="{{ $source['url'] }}" media="{{ $source['media'] }}">
        @endif
    @endforeach
    <img src="{{ last($sources)['url'] }}" alt="{{ $alt }}" {{ $attributes->merge(['loading' => 'lazy', 'decoding' => 'async']) }}>
</picture>
