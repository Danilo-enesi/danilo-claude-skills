@props(['title'])

<picture>
    @if($media)
        @if($media->hasGeneratedConversion($thumbName."_webp"))
            <source type="image/webp" srcset="{!! $media->getUrl($thumbName."_webp") !!}">
        @endif
        <source type="{{$media->mime_type}}" srcset="{!! $media->getUrl($thumbName) !!}">
        <img {!! $data_attr !!} src="{!! $media->getUrl($thumbName) !!}" title="{{$title}}" alt="{{$title}}" class="{!! $classes !!}" />
    @else
        <source type="image/webp" srcset="/assets/main/images/defaults/{{Str::replaceLast('image', 'thumb-tablet', $default)}}.webp" media="(min-width: 992px)">
        <source type="image/webp" srcset="/assets/main/images/defaults/{{$default}}.webp" media="(min-width: 469px)">
        <source type="image/jpeg" srcset="/assets/main/images/defaults/{{Str::replaceLast('image', 'thumb-tablet', $default)}}.jpg" media="(min-width: 992px)">
        <source type="image/jpeg" srcset="/assets/main/images/defaults/{{$default}}.jpg" media="(min-width: 469px)">

        <img {!! $data_attr !!} src="/assets/main/images/defaults/{{$default}}.jpg" @class([$classes]) loading="lazy" title="{{$title}}" alt="{{$title}}" decoding="async">
    @endif
</picture>
